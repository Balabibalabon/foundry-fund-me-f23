//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
// import "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant START_BALANCE = 10 ether;

    function setUp() external {
        // us call-> FundMeTest call-> FundMe
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BALANCE);
    }

    function testMinimunDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        // assertEq(fundMe.i_owner(), msg.sender);
        // assertEq(fundMe.i_owner(), address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccuratye() public view {
        uint256 version = fundMe.getVersion();
        console.log(version);
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // 代表皆在這行之後的應該要 revert
        fundMe.fund(); // 不傳送任何值，會 revert
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // 接下來的訊息會由 USER 發送，可以確定是誰發送的，叫好檢查
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 GAS_PRICE = 1;
        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);
        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            (startingOwnerBalance + startingFundMeBalance)
        );
    }

    function testWithfrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; // uint160 與 address bits 數相同，在這邊當地址用
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            fundMe.getOwner().balance
        );
    }

    function testWithfrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10; // uint160 與 address bits 數相同，在這邊當地址用
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        // Act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperwithdraw();
        // Assert
        assert(address(fundMe).balance == 0);
        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            fundMe.getOwner().balance
        );
    }

    // 4 types of testing
    // 1. Unit: Testing a single function
    // 2. Integration: Testing multiple functions
    // 3. Forked: Testing on a forked network
    // 4. Staging: Testing on a live network (testnet or mainnet)

    // 在 Sepolia 上進行測試，會消耗 Node 點數 forge test --match-test testPriceFeedVersionIsAccuratye -vvv --fork-url $SEPOLIA_RPC_URL
    // 計算測試程式碼所包含的量，越高越好 forge coverage --fork-url $SEPOLIA_RPC_URL
}
