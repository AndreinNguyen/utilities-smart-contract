const { ethers, expect } = require("../libary.js");
describe("Collection and Clone contract", function () {
  let owner;
  let otherAccount;
  let back_end;
  let collection;
  before(async () => {
    [owner, otherAccount, back_end] = await ethers.getSigners();

    const Collection = await ethers.getContractFactory("collection");
    collection = await Collection.deploy(back_end.address);
    await collection.deployed();
  });
  describe("Collection", () => {
    let connect_back_end;
    let collectionIds;
    let owner_address;

    before(async () => {
      connect_back_end = collection.connect(back_end);
    });
    it("create new Collection", async function () {
      let create_new_collection = await connect_back_end.createCollection(
        
        back_end.address
      );
      let expect_collection_id = 1;
      const rc = await create_new_collection.wait();
      const event = rc.events.find(
        (event) => event.event === "CreateCollection"
      );

      [ collectionIds, owner_address] = event.args;
      expect(collectionIds).to.equal(expect_collection_id);
    });
    it("create new Collection emit event", async function () {
      let create_new_collection = await connect_back_end.createCollection(
        
        back_end.address
      );
      await expect(create_new_collection).to.emit(
        collection,
        "CreateCollection"
      );
    });
  });
});
