const { ethers, expect } = require("../libary.js");

describe("NFT1155 contract", function () {
  let owner;
  let otherAccount;
  let back_end;
  let nft1155;
  let MKP;
  before(async () => {
    [owner, otherAccount, back_end, fee_receipient] = await ethers.getSigners();

    const NFT_1155 = await ethers.getContractFactory("NFT_1155");
    nft1155 = await NFT_1155.deploy("", back_end.address);
    await nft1155.deployed();
    const Marketplace = await ethers.getContractFactory("Marketplace");
    MKP = await Marketplace.deploy(
      back_end.address,
      nft1155.address,
      fee_receipient.address,
      ethers.utils.parseEther("1"),
      ethers.utils.parseEther("2.5")
    );
    await MKP.deployed();
    
  });
  describe("NFT", () => {
    let creator1;
    let creator2;
    let creator3;
    let newNFTid1;
    let newNFTid2;
    let newNFTid3;
    let creator_connect;
    before(async () => {
      creator_connect = nft1155.connect(owner);
      connect_back_end = nft1155.connect(back_end);
      connect_back_end.setMKPAddress(MKP.address);
    });
    describe("Mint NFT", () => {
      it("mint NFT success ", async function () {
        let NFT_URI = "";
        let amount1 = 1;
        let amount2 = 4;
        let amount3 = 9;
        let mintNFT_1 = await creator_connect.create1155NFT(
          
          owner.address,
          NFT_URI,
          amount1
        );
        const rc1 = await mintNFT_1.wait(); // 0ms, as tx is already confirmed
        const event1 = rc1.events.find(
          (event1) => event1.event === "Create1155NFT"
        );
        [ creator1, newNFTid1] = event1.args;

        let mintNFT_2 = await creator_connect.create1155NFT(
          
          owner.address,
          NFT_URI,
          amount2
        );
        const rc2 = await mintNFT_2.wait(); // 0ms, as tx is already confirmed
        const event2 = rc2.events.find(
          (event2) => event2.event === "Create1155NFT"
        );
        [ creator2, newNFTid2] = event2.args;

        let mintNFT_3 = await creator_connect.create1155NFT(
          
          owner.address,
          NFT_URI,
          amount3
        );
        const rc3 = await mintNFT_3.wait(); // 0ms, as tx is already confirmed
        const event3 = rc3.events.find(
          (event3) => event3.event === "Create1155NFT"
        );
        [ creator3, newNFTid3] = event3.args;
        let balanceOfNFT1 = await creator_connect.balanceOf(
          creator1,
          newNFTid1
        );
        let balanceOfNFT2 = await creator_connect.balanceOf(
          creator2,
          newNFTid2
        );
        let balanceOfNFT3 = await creator_connect.balanceOf(
          creator3,
          newNFTid3
        );
        expect(balanceOfNFT1).to.equal(amount1);
        expect(balanceOfNFT2).to.equal(amount2);
        expect(balanceOfNFT3).to.equal(amount3);
      });
    });

    describe("Transfer NFT", () => {
      let signature1;
      before(async() => {
        const domain = {
          name: "permission",
          version: "1",
          chainId: 31337,
          verifyingContract: nft1155.address,
        }
        const types = {
          Permit: [
            { name: "_owner", type: "address" },
            { name: "_spender", type: "address" },
            { name: "_NFTId", type: "uint256" },
            { name: "_amount", type: "uint256" },
            { name: "_nonce", type: "uint256" },
          ],
        }
        const value1 = 
        {
          _owner: owner.address,
          _spender: nft1155.address,
          _NFTId: 1,
          _amount: 1,
          _nonce: 0,
        }
        
        signature1 = await owner._signTypedData(
          domain,
          types,
          value1
          
        );
      })
      it("transfer NFT success ", async function () {
        let amount = 1;
        await creator_connect.transfer1155NFT(
          
          owner.address,
          otherAccount.address,
          newNFTid1,
          amount,
          signature1
        );
        expect(
          await nft1155.balanceOf(otherAccount.address, newNFTid1)
        ).to.equal(amount);
      });
      it("transfer NFT with insufficient balance ", async function () {
        let amount_insufficient = 100;
        await expect(
          creator_connect.transfer1155NFT(
            
            owner.address,
            otherAccount.address,
            newNFTid1,
            amount_insufficient,
            signature1
          )
        ).to.be.revertedWith("insufficient balance for transfer");
      });
      it("transfer non existed NFT", async function () {
        let non_existed_Id = 100;

        await expect(
          creator_connect.transfer1155NFT(
            
            owner.address,
            otherAccount.address,
            non_existed_Id,
            1,
            signature1
          )
        ).to.be.revertedWith("insufficient balance for transfer");
      });
      it("transfer NFT by invalid owner", async function () {
        let not_owner = nft1155.connect(otherAccount);

        await expect(
          not_owner.transfer1155NFT(
            
            owner.address,
            otherAccount.address,
            newNFTid1,
            1,
            signature1
          )
        ).to.be.revertedWith("transfer from invalid owner");
      });
    });
    describe("Approve NFT", () => {
      it("Approve NFT success", async function () {
        let approve = await creator_connect.approveAll1155NFT(
          
          owner.address,
          nft1155.address,
          true
        );
        await expect(approve).to.emit(nft1155, "ApproveAll1155NFT");
      });
      it("Approve NFT with invalid owner", async function () {
        let invalid_approver = nft1155.connect(otherAccount);
        await expect(
          invalid_approver.approveAll1155NFT(
            
            owner.address,
            nft1155.address,
            true
          )
        ).to.be.revertedWith("approve from invalid owner");
      });
    });
    describe("NFT total supply", () => {
      it("get NFT total supply success", async function () {
        let total_supply = await creator_connect.totalSupply(newNFTid3);
        let expected_total_supply = 9;
        expect(total_supply).to.equal(expected_total_supply);
      });
      it("get NFT total supply fail", async function () {
        let non_existed_Id = 100;

        await expect(
          creator_connect.totalSupply(non_existed_Id)
        ).to.be.revertedWith("NFT not released");
      });
    });
  });
});
