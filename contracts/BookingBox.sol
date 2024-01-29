// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BookingBox is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _totalHomestaysListed; // Total number of homestays listed.

    struct HomestayStructure {
        // Structure for Homestay Details
        uint id;
        string name;
        string description;
        string location;
        string images;
        uint rooms;
        uint price;
        address owner;
        bool booked;
        bool deleted;
        uint timestamp;
    }

    struct BookingStructure {
        // Structure for booking a Homestay
        uint id; // Unique Booking ID
        uint aid; // Homestay ID
        address tenant;
        uint date;
        uint price;
        bool checkedIn;
        bool cancelled;
    }

    struct ReviewStructure {
        // Stay Review for the booked Homestay
        uint id;
        uint aid;
        string reviewText;
        uint timestamp;
        address owner;
    }

    // aid stands for Apartment/Homestay ID.

    uint public taxPercent;
    uint public securityFee;

    mapping(uint => HomestayStructure) homestays;
    mapping(uint => BookingStructure[]) bookingsOf;
    mapping(uint => ReviewStructure[]) reviewsOf;
    mapping(uint => bool) homestayExist;
    mapping(uint => uint[]) bookedDates;
    mapping(uint => mapping(uint => bool)) isDateBooked;
    mapping(address => mapping(uint => bool)) hasBooked;

    constructor(uint _taxPercent, uint _securityFee) {
        taxPercent = _taxPercent;
        securityFee = _securityFee;
    }

    // Helper Functions.
    function currentTime() internal view returns (uint256) {
        return (block.timestamp * 1000) + 1000;
    }

    function datesAvailable(
        uint aid,
        uint[] memory dates
    ) internal view returns (bool) {
        bool datesAvailableForBooking = true;
        for (uint i = 0; i < dates.length; i++) {
            for (uint j = 0; j < bookedDates[aid].length; j++) {
                if (dates[i] == bookedDates[aid][j]) datesAvailableForBooking = false;
            }
        }
        return datesAvailableForBooking;
    }

    function payTo(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success);
    }

    // Main Functions.
    function createHomestay(
        string memory name,
        string memory description,
        string memory location,
        string memory images,
        uint rooms,
        uint price
    ) public {
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(location).length > 0, "Location cannot be empty");
        require(bytes(images).length > 0, "Images cannot be empty");
        require(rooms > 0, "Rooms cannot be zero");
        require(price > 0 ether, "Price cannot be zero");

        _totalHomestaysListed.increment();
        HomestayStructure memory lodge;
        lodge.id = _totalHomestaysListed.current();
        lodge.name = name;
        lodge.description = description;
        lodge.location = location;
        lodge.images = images;
        lodge.rooms = rooms;
        lodge.price = price;
        lodge.owner = msg.sender;
        lodge.timestamp = currentTime();

        homestayExist[lodge.id] = true;
        homestays[_totalHomestaysListed.current()] = lodge;
    }

    function updateHomestay(
        uint id,
        string memory name,
        string memory description,
        string memory location,
        string memory images,
        uint rooms,
        uint price
    ) public {
        require(homestayExist[id] == true, "Homestay not found");
        require(
            msg.sender == homestays[id].owner,
            "Unauthorized personnel, Owner only"
        );
        require(bytes(name).length > 0, "Name cannot be empty");
        require(bytes(description).length > 0, "Description cannot be empty");
        require(bytes(location).length > 0, "Location cannot be empty");
        require(bytes(images).length > 0, "Images cannot be empty");
        require(rooms > 0, "Rooms cannot be zero");
        require(price > 0, "Price cannot be zero");

        HomestayStructure memory lodge = homestays[id];
        lodge.name = name;
        lodge.description = description;
        lodge.location = location;
        lodge.images = images;
        lodge.rooms = rooms;
        lodge.price = price;

        homestays[id] = lodge;
    }

    function deleteHomestay(uint id) public {
        require(homestayExist[id] == true, "Homestay not found");
        require(homestays[id].owner == msg.sender, "Unauthorized Entity");

        homestayExist[id] = false;
        homestays[id].deleted = true;
    }

    function getHomestays()
        public
        view
        returns (HomestayStructure[] memory Homestays)
    {
        uint256 availableHomestays;
        for (uint i = 1; i <= _totalHomestaysListed.current(); i++) {
            if (!homestays[i].deleted) availableHomestays++;
        }
        Homestays = new HomestayStructure[](availableHomestays);

        uint256 index;
        for (uint i = 1; i <= _totalHomestaysListed.current(); i++) {
            if (!homestays[i].deleted) {
                Homestays[index++] = homestays[i];
            }
        }
    }

    function getHomestay(
        uint id
    ) public view returns (HomestayStructure memory) {
        return homestays[id];
    }

    function bookHomestay(uint aid, uint[] memory dates) public payable {
        uint totalPriceDuringStay = homestays[aid].price * dates.length;
        uint totalSecurityFeeDuringStay = (homestays[aid].price *
            dates.length) / 100;

        require(homestayExist[aid], "Homestay not found");
        require(
            msg.value >= totalPriceDuringStay + totalSecurityFeeDuringStay,
            "Insufficient funds!"
        );
        require(datesAvailable(aid, dates), "Booked date found among dates!");

        for (uint i = 0; i < dates.length; i++) {
            BookingStructure memory booking;
            booking.aid = aid;
            booking.id = bookingsOf[aid].length;
            booking.tenant = msg.sender;
            booking.date = dates[i];
            booking.price = homestays[aid].price;

            bookingsOf[aid].push(booking);
            isDateBooked[aid][dates[i]] = true;
            bookedDates[aid].push(dates[i]);
            // hasBooked[msg.sender][dates[i]] = true;
        }
    }

    function checkInHomestay(uint aid, uint bookingId) public nonReentrant() {
        BookingStructure memory booking = bookingsOf[aid][bookingId];
        require(msg.sender == booking.tenant, "Unauthorized tenant!");
        require(!booking.checkedIn, "Homestay already Checked-in!");

        bookingsOf[aid][bookingId].checkedIn = true;
        uint tax = (booking.price * taxPercent) / 100;
        uint fee = (booking.price * securityFee) / 100;

        hasBooked[msg.sender][aid] = true;

        payTo(homestays[aid].owner, (booking.price - tax));
        payTo(owner(), tax);
        payTo(msg.sender, fee);
    }

    function claimFunds(uint aid, uint bookingId) public {
        require(msg.sender == homestays[aid].owner, "Unauthorized Entity!");
        require(
            !bookingsOf[aid][bookingId].checkedIn,
            "Homestay already checked-in on this date!"
        );

        uint price = bookingsOf[aid][bookingId].price;
        uint fee = (price * taxPercent) / 100;

        payTo(homestays[aid].owner, (price - fee));
        payTo(owner(), fee);
        payTo(msg.sender, securityFee);
    }

    function refundBooking(uint aid, uint bookingId) public nonReentrant() {
        BookingStructure memory booking = bookingsOf[aid][bookingId];
        require(
            !booking.checkedIn,
            "Homestay already checked-in on this date!"
        );

        if (msg.sender != owner()) {
            require(msg.sender == booking.tenant, "Unauthorized tenant!");
            require(
                booking.date > currentTime(),
                "Can no longer refund, booking date started!"
            );
        }

        bookingsOf[aid][bookingId].cancelled = true;
        isDateBooked[aid][booking.date] = false;

        uint lastIndex = bookedDates[aid].length - 1;
        uint lastBookingId = bookedDates[aid][lastIndex];
        bookedDates[aid][bookingId] = lastBookingId;
        bookedDates[aid].pop();

        uint fee = (booking.price * securityFee) / 100;
        uint collateral = fee / 2;

        payTo(homestays[aid].owner, collateral);
        payTo(owner(), collateral);
        payTo(msg.sender, booking.price);
    }

    function getUnavailableDates(uint aid) public view returns (uint[] memory) {
        return bookedDates[aid];
    }

    function getBookings(
        uint aid
    ) public view returns (BookingStructure[] memory) {
        return bookingsOf[aid];
    }

    function getQualifiedReviews(
        uint aid
    ) public view returns (address[] memory Tenants) {
        uint256 available;
        for (uint i = 0; i < bookingsOf[aid].length; i++) {
            if (bookingsOf[aid][i].checkedIn) available++;
        }

        Tenants = new address[](available);

        uint256 index;
        for (uint i = 0; i < bookingsOf[aid].length; i++) {
            if (bookingsOf[aid][i].checkedIn) {
                Tenants[index++] = bookingsOf[aid][i].tenant;
            }
        }
    }

    function getBooking(
        uint aid,
        uint bookingId
    ) public view returns (BookingStructure memory) {
        return bookingsOf[aid][bookingId];
    }

    function addReview(uint aid, string memory reviewText) public {
        require(homestayExist[aid], "Homestay not available!");
        require(hasBooked[msg.sender][aid], "Book first before review");
        require(bytes(reviewText).length > 0, "Review text cannot be empty!");

        ReviewStructure memory review;

        review.aid = aid;
        review.id = reviewsOf[aid].length;
        review.reviewText = reviewText;
        review.timestamp = currentTime();
        review.owner = msg.sender;

        reviewsOf[aid].push(review);
    }

    function getReviews(
        uint aid
    ) public view returns (ReviewStructure[] memory) {
        return reviewsOf[aid];
    }

    function tenantBooked(uint homestayId) public view returns (bool) {
        return hasBooked[msg.sender][homestayId];
    }
}
