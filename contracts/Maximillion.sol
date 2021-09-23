pragma solidity ^0.5.16;

import "./MBnb.sol";

/**
 * @title MoleCity's Maximillion Contract
 * @author MoleCity
 */
contract Maximillion {
    /**
     * @notice The default mBNB market to repay in
     */
    MBnb public mBNB;

    /**
     * @notice Construct a Maximillion to repay max in a MBnb market
     */
    constructor(MBnb mBNB_) public {
        mBNB = mBNB_;
    }

    /**
     * @notice msg.sender sends ETH to repay an account's borrow in the mETH market
     * @dev The provided ETH is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     */
    function repayBehalf(address borrower) public payable {
        repayBehalfExplicit(borrower, mBNB);
    }

    /**
     * @notice msg.sender sends ETH to repay an account's borrow in a mETH market
     * @dev The provided ETH is applied towards the borrow balance, any excess is refunded
     * @param borrower The address of the borrower account to repay on behalf of
     * @param mBNB_ The address of the mETH contract to repay in
     */
    function repayBehalfExplicit(address borrower, MBnb mBNB_) public payable {
        uint received = msg.value;
        uint borrows = mBNB_.borrowBalanceCurrent(borrower);
        if (received > borrows) {
            mBNB_.repayBorrowBehalf.value(borrows)(borrower);
            msg.sender.transfer(received - borrows);
        } else {
            mBNB_.repayBorrowBehalf.value(received)(borrower);
        }
    }
}
