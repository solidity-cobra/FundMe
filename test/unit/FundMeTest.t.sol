// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //GIVING FAKE USER A BALANCE SO AS TO TEST OUR TRANSACTION
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testNotOwner() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testGetVersion() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithOutEnoughETH() public {
        //this test is under function fund
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdateFundedDataStructure() public {
        //this test is under function fund
        // we want to create a fake user using makeAdrr to send the fund...state variable above which is user

        vm.prank(USER); // THIS MEANS THE NEXT TX WILL BE SENT BY USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
        // assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddsFundersToArraysOfFunders() public {
        //this test is under function fund
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
        // assertEq(fundMe.getFunder(0), USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER); //the user (this line and the next were used in the mordifier FUNDED)
        // fundMe.fund{value: SEND_VALUE}(); //fund it with sum money

        vm.prank(USER); //user tries to withdraw as the user is not the owner.....it is expected to revert and the test passed
        vm.expectRevert(); //expect revert

        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange test

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act....the action

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function tesstWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //to use numbers to generate addresses, we use uint160
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank ....to create addresses
            //vm.deal....to fund
            //fund fundme
            //hoax...a cheat code that set up a prank from an address that come with some eth
            hoax(address(i), SEND_VALUE); //we are creating a blank address of i,which starts as index 1
            fundMe.fund{value: SEND_VALUE}(); //this many funders loop through the list and fund the fundMe
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function tesstWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //to use numbers to generate addresses, we use uint160
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank ....to create addresses
            //vm.deal....to fund
            //fund fundme
            //hoax...a cheat code that set up a prank from an address that come with some eth
            hoax(address(i), SEND_VALUE); //we are creating a blank address of i,which starts as index 1
            fundMe.fund{value: SEND_VALUE}(); //this many funders loop through the list and fund the fundMe
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
