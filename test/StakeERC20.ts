import { time, loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { SaveERC20__factory} from "../typechain-types";
import { parseEther } from "ethers";

describe("SaveERC20", function () {
  let owner: any, Address1: any, Address2: any;
  let saveERC20: any;
  let contractBalance = ethers.parseUnits("0", 18);

  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  beforeEach(async function () {
    const SaveERC20 = (await ethers.getContractFactory("SaveERC20")) as SaveERC20__factory;
    [owner, Address1] = await ethers.getSigners();
    saveERC20 = await SaveERC20.deploy();
  });

  it("it should check balance", async function () {
    expect(await saveERC20.checkContractBal()).to.equal(contractBalance);
  });

  it("it should deposit amount", async function () {
    await saveERC20.connect(owner).deposit({ value: ethers.parseUnits("1", 18) });
    expect(await saveERC20.checkContractBal()).to.equal(ethers.parseUnits("1", 18));
  });

    });
});