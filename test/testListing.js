const { ethers, expect } = require("../libary.js");


describe("Test Listing and Buy function", function () {
  let owner;
  let otherAccount;
  let back_end;
  let MKP;
  let nft1155;
  let svc;
  let connect_back_end;
  let connect_owner;
  let NFTid1 = 1;
  let NFTid2 = 2;
  let NFTid3 = 3;
  let NFT_URI = "";
  let amount1 = 1;
  let amount2 = 4;
  let amount3 = 9;
  let chainId_local = 31337;
  let signature1;
  let signature2;
  let signature3;
  before(async () => {
    [owner, otherAccount, back_end, fee_receipient] = await ethers.getSigners();
    const NFT_1155 = await ethers.getContractFactory("NFT_1155");
    nft1155 = await NFT_1155.deploy("", back_end.address);
    await nft1155.deployed();

    const SVCToken = await ethers.getContractFactory("SVCToken");
    svc = await SVCToken.connect(owner).deploy(
      "name",
      "symbol",
      ethers.utils.parseEther("10000.0")
    );
    await svc.deployed();

    const Marketplace = await ethers.getContractFactory("Marketplace");
    MKP = await Marketplace.deploy(
      back_end.address,
      nft1155.address,
      fee_receipient.address,
      ethers.utils.parseEther("1"),
      ethers.utils.parseEther("2.5")
    );
    await MKP.deployed();
    connect_back_end = MKP.connect(back_end);
    connect_owner = MKP.connect(owner);
    let mintNFT_1 = await nft1155
      .connect(owner)
      .create1155NFT(owner.address, NFT_URI, amount1);
    let mintNFT_2 = await nft1155
      .connect(owner)
      .create1155NFT(owner.address, NFT_URI, amount2);
    await nft1155.connect(back_end).setMKPAddress(MKP.address);
    let mintNFT_3 = await nft1155
      .connect(owner)
      .create1155NFT(owner.address, NFT_URI, amount3);
    await nft1155.connect(back_end).setMKPAddress(MKP.address);
    const domain = {
      name: "permission",
      version: "1",
      chainId: chainId_local,
      verifyingContract: nft1155.address,
    }
    const types = {
      Permit: [
        { name: "_owner", type: "address" },
        { name: "_spender", type: "address" },
        { name: "_NFTId", type: "uint256" },
        { name: "_price", type: "uint256" },
      ],
    }
    const value1 = 
    {
      _owner: owner.address,
      _spender: nft1155.address,
      _NFTId: NFTid1,
      _price: 10
    }
    const value2 = 
    {
      _owner: owner.address,
      _spender: nft1155.address,
      _NFTId: NFTid2,
      _price: 10
    }
    let value3 = {
      _owner: owner.address,
      _spender: nft1155.address,
      _NFTId: NFTid3,
      _price: 10
    }
    signature1 = await owner._signTypedData(
      domain,
      types,
      value1
      
    );
    signature2 = await owner._signTypedData(
      domain,
      types,
      value2
      
    );
    signature3 = await owner._signTypedData(
      domain,
      types,
      value3
      
    );
  });
  describe("Listing", () => {
    it("Test Listing happy case", async function () {

      await connect_back_end.listing(signature1,amount1);
      let expect_listing = true;
      let check_listing = await connect_back_end.checkListed(
        signature1
      );
      expect(check_listing).to.equal(expect_listing);
    });
    it("Test Listing event", async function () {

      let listing = await connect_back_end.listing(signature2, amount2);
      await expect(listing).to.emit(MKP, "Listing");
    });
    it("Test Listing invalid dev address", async function () {

      let listing = MKP.connect(owner).listing(signature2, amount2);
      await expect(listing).to.be.revertedWith("invalid dev address");
    });
  });
  describe("Buy", () => {
    let NFTid1 = 1;
    let NFTid2 = 2;
    let NFTid3= 3;

    let nonce;

    before(async () => {
      nonce = 0;
      await connect_back_end.listing(ethers.utils.hexlify(signature1), amount1);

      await connect_back_end.listing(ethers.utils.hexlify(signature2), amount2);

      await connect_back_end.listing(ethers.utils.hexlify(signature3), amount3);
      await svc
        .connect(owner)
        .approve(owner.address, ethers.utils.parseEther("100"));
      await svc
        .connect(owner)
        .transferFrom(
          owner.address,
          otherAccount.address,
          ethers.utils.parseEther("100")
        );
    });
    it("Test Buy happy case", async function () {
      const domain = {
        name: "permission",
        version: "1",
        chainId: chainId_local,
        verifyingContract: nft1155.address,
      }
      const types = {
        Permit: [
          { name: "_owner", type: "address" },
          { name: "_spender", type: "address" },
          { name: "_NFTId", type: "uint256" },
          { name: "_price", type: "uint256" }
        ],
      }
      const value = 
      {
        _owner: owner.address,
        _spender: nft1155.address,
        _NFTId: NFTid1,
        _price: ethers.utils.parseEther("10")
      }
      
      let signature = await owner._signTypedData(
        domain,
        types,
        value
      );

    
      //sell maker, taker, payment
      let address_array = [
        owner.address,
        otherAccount.address,
        svc.address,
        otherAccount.address,
        owner.address,
        svc.address,
      ];
      let price = ethers.utils.parseEther("10");
      let listing_time = ethers.utils.parseEther("5.0");
      let expiration_time = ethers.utils.parseEther("8.0");
      let uint_array = [
        price,
        listing_time,
        expiration_time,
        NFTid1,
        amount1,
        nonce,
        price,
        listing_time,
        expiration_time,
        NFTid1,
        amount1,
        nonce,
      ];
      await svc
        .connect(otherAccount)
        .approve(MKP.address, ethers.utils.parseEther("10"));
      await MKP.connect(otherAccount).atomicMatch(
        address_array,
        uint_array,
        ethers.utils.hexlify(signature)
      );
      let NFTbalance = await nft1155.balanceOf(otherAccount.address, NFTid1);
      let token_balance = await svc.balanceOf(owner.address);
      let expect_NFT_balance = 1;
      let token_balance_decimal = 10000 - 100 + 10 - 0.25 - 0.1 + 0.1;
      let expect_token_balance = ethers.utils.parseEther(
        token_balance_decimal.toString()
      );
      expect(NFTbalance).to.equal(expect_NFT_balance);
      expect(token_balance).to.equal(expect_token_balance);
      nonce++;
    });
    it("Test Buy event", async function () {
      let signature = await owner._signTypedData(
        {
          name: "permission",
          version: "1",
          chainId: chainId_local,
          verifyingContract: nft1155.address,
        },
        {
          Permit: [
            { name: "_owner", type: "address" },
            { name: "_spender", type: "address" },
            { name: "_NFTId", type: "uint256" },
            { name: "_price", type: "uint256" }
          ],
        },
        {
          _owner: owner.address,
          _spender: nft1155.address,
          _NFTId: NFTid2,
          _price: ethers.utils.parseEther("10")
        }
      );
  
      //sell maker, taker, payment
      let address_array = [
        owner.address,
        otherAccount.address,
        svc.address,
        otherAccount.address,
        owner.address,
        svc.address,
      ];
      let price = ethers.utils.parseEther("10");
      let listing_time = ethers.utils.parseEther("5.0");
      let expiration_time = ethers.utils.parseEther("8.0");
      let uint_array = [
        price,
        listing_time,
        expiration_time,
        NFTid2,
        amount2,
        nonce,
        price,
        listing_time,
        expiration_time,
        NFTid2,
        amount2,
        nonce,
      ];
      await svc
        .connect(otherAccount)
        .approve(MKP.address, ethers.utils.parseEther("10"));
      let buy = await MKP.connect(otherAccount).atomicMatch(
        address_array,
        uint_array,
       signature
      );
      nonce++;
      await expect(buy).to.emit(MKP, "AtomicMatch");
    });
    it("Test Buy with native token", async function () {

      let signature = await owner._signTypedData(
        {
          name: "permission",
          version: "1",
          chainId: chainId_local,
          verifyingContract: nft1155.address,
        },
        {
          Permit: [
            { name: "_owner", type: "address" },
            { name: "_spender", type: "address" },
            { name: "_NFTId", type: "uint256" },
            { name: "_price", type: "uint256" }
          ],
        },
        {
          _owner: owner.address,
          _spender: nft1155.address,
          _NFTId: NFTid3,
          _price: ethers.utils.parseEther("10"),
        }
      );
 
      //sell maker, taker, payment
      let address_array = [
        owner.address,
        otherAccount.address,
        ethers.constants.AddressZero,
        otherAccount.address,
        owner.address,
        ethers.constants.AddressZero,
      ];
      let price = ethers.utils.parseEther("10");
      let listing_time = ethers.utils.parseEther("5.0");
      let expiration_time = ethers.utils.parseEther("8.0");
      let uint_array = [
        price,
        listing_time,
        expiration_time,
        NFTid3,
        amount3,
        nonce,
        price,
        listing_time,
        expiration_time,
        NFTid3,
        amount3,
        nonce,
      ];
      await svc
        .connect(otherAccount)
        .approve(MKP.address, ethers.utils.parseEther("10"));
      await MKP.connect(otherAccount).atomicMatch(
        address_array,
        uint_array,
        signature,{value: ethers.utils.parseEther("10")}
      );
      let NFTbalance = await nft1155.balanceOf(otherAccount.address, NFTid1);
      let token_balance = await svc.balanceOf(owner.address);
      let expect_NFT_balance = 1;
      let token_balance_decimal = 9919.5;
      let expect_token_balance = ethers.utils.parseEther(
        token_balance_decimal.toString()
      );
      expect(NFTbalance).to.equal(expect_NFT_balance);
      expect(token_balance).to.equal(expect_token_balance);
      nonce++;
    });
    it("Test Buy with invalid owner", async function () {
      
      
      const domain = {
        name: "permission",
        version: "1",
        chainId: chainId_local,
        verifyingContract: nft1155.address,
      }
      const types = {
        Permit: [
          { name: "_owner", type: "address" },
          { name: "_spender", type: "address" },
          { name: "_NFTId", type: "uint256" },
          { name: "_price", type: "uint256" }
        ],
      }
      const value = 
      {
        _owner: owner.address,
        _spender: nft1155.address,
        _NFTId: NFTid3,
        _price: ethers.utils.parseEther("10")
      }
      let signature = await otherAccount._signTypedData(
        domain, types, value
        
      );
      await connect_back_end.listing(signature);
      //sell maker, taker, payment
      let address_array = [
        otherAccount.address,
        owner.address,
        svc.address,
        owner.address,
        otherAccount.address,
        svc.address,
      ];
      let price = ethers.utils.parseEther("10");
      let listing_time = ethers.utils.parseEther("5.0");
      let expiration_time = ethers.utils.parseEther("8.0");
      let uint_array = [
        price,
        listing_time,
        expiration_time,
        NFTid3,
        amount3,
        0+1,
        price,
        listing_time,
        expiration_time,
        NFTid3,
        amount3,
        0+1,
      ];
      await svc
        .connect(owner)
        .approve(MKP.address, ethers.utils.parseEther("10"));
      let buy = MKP.connect(owner).atomicMatch(
        address_array,
        uint_array,
        signature
      );

      await expect(buy).to.be.revertedWith("invalid owner");
    });
  });
});
