module.exports = [
  process.env.DEV_WALLET,
  "0x858EC92c52e26cE4a6ACd5E02932340dfF60FDA7",
  process.env.FEE_WALLET,
  10,
  25,
];
//npx hardhat verify --constructor-args ./scripts/argumentsMKP.js 0x8187FC9461154c8371f715a6624D2BAc09A234F6 --network polygonMumbai