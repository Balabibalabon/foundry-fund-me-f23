//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
// import "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract InteractionsTest is Test {
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

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        vm.prank(USER);
        vm.deal(USER, 1e18);
        fundFundMe.fundFundMe(address(fundMe));

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testUserCanWithdrawInteractions() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundMe));

        assert(address(fundMe).balance == 0);
    }
}
