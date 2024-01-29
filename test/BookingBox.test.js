import { before, beforeEach, describe, it } from "node:test";

const { expect } = require("chai");
const { hre } = require("hardhat");

const toWei = (num) => hre.ethers.parseEther(num.toString());
const fromWei = (num) => hre.ethers.formatEther(num);

const dates1 = [170124123543, 170124051259, 240224112332];
const dates2 = [1678752000000, 1678838400000];

describe("Contracts", () => {
  let contract, result;
  const id = 1;
  const bookingId = 0;
  const taxPercent = 5;
  const securityFee = 2;
  const name = "Heaven's Paradise Homestay";
  const location = "Bangalore";
  const newName = "Update Homestay";
  const description =
    "Best Homestay in the city, rated 7 stars by Homestay Ranks and Ratings World(HRRW)!";
  const images = [
    "https://a0.muscache.com/im/pictures/miso/Hosting-3524556/original/24e9b114-7db5-4fab-8994-bc16f263ad1d.jpeg?im_w=720",
    "https://a0.muscache.com/im/pictures/miso/Hosting-5264493/original/10d2c21f-84c2-46c5-b20b-b51d1c2c971a.jpeg?im_w=720",
    "https://a0.muscache.com/im/pictures/prohost-api/Hosting-584469386220279136/original/227d4c26-43d5-42da-ad84-d039515c0bad.jpeg?im_w=720",
    "https://a0.muscache.com/im/pictures/miso/Hosting-610511843622686196/original/253bfa1e-8c53-4dc0-a3af-0a75728c0708.jpeg?im_w=720",
    "https://a0.muscache.com/im/pictures/miso/Hosting-535385560957380751/original/90cc1db6-d31c-48d5-80e8-47259e750d30.jpeg?im_w=720",
  ];
  const rooms = 4;
  const price = 3.2;
  const newPrice = 2.0;

  beforeEach(async () => {
    [deployer, owner, tenant1, tenant2] = await hre.ethers.getSigner();
    contract = await hre.ethers.deployContract("BookingBox", [
      taxPercent,
      securityFee,
    ]);
    await contract.waitForDeployment();
  });

  // Homestay Test.
  describe("Homestay", () => {
    beforeEach(async () => {
      await contract
        .connect(owner)
        .createHomestay(
          name,
          description,
          location,
          images.join(","),
          rooms,
          toWei(price)
        );
    });

    it("Should confirm homestay in array", async () => {
      result = await contract.getHomestays();
      expect(result).to.have.lengthOf(1);

      result = await contract.getHomestay(id);
      expect(result.name).to.be.equal(name);
      expect(result.description).to.be.equal(description);
      expect(result.images).to.be.equal(images.join(","));
    });

    it("Should confirm homestay update", async () => {
      result = await contract.getHomestay(id);
      expect(result.name).to.be.equal(name);
      expect(result.price).to.be.equal(toWei(price));

      await contract
        .connect(owner)
        .updateHomestay(
          id,
          newName,
          description,
          location,
          images.join(","),
          rooms,
          toWei(newPrice)
        );

        result = await contract.getHomestay(id);
        expect(result.name).to.be.equal(newName);
        expect(result.price).to.be.equal(toWei(price));
    });

    it("Should confirm homestay deletion", async() => {
        result = await contract.getHomestays()
        expect(result).to.have.lengthOf(1);

        result = await contract.getHomestay(id);
        expect(result).to.be.equal(false);

        await contract.connect(owner).deleteHomestay(id);

        result = await contract.getHomestay();
        expect(result).to.have.lengthOf(0);

        result = await contract.getHomestay(id);
        expect(result.deleted).to.be.equal(true);
    });
  });

  // Booking Test
});
