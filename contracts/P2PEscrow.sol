// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract P2PCryptoEscrow {
    enum TradeStatus { NONE, LOCKED, FIAT_SENT, COMPLETED, REFUNDED }
    
    struct Trade {
        address seller;
        address buyer;
        uint256 amount;
        address token;
        uint256 lockTime;
        TradeStatus status;
    }
    
    mapping(uint256 => Trade) public trades;
    uint256 public tradeCounter;
    uint256 public constant TIMEOUT_PERIOD = 1 hours;
    
    event FundsLocked(uint256 tradeId, address seller, address buyer, uint256 amount);
    event FiatMarkedSent(uint256 tradeId, address buyer);
    event FundsReleased(uint256 tradeId, address seller, address buyer);
    event FundsRefunded(uint256 tradeId, address seller);
    
    modifier onlySeller(uint256 tradeId) {
        require(msg.sender == trades[tradeId].seller, "Not seller");
        _;
    }
    
    modifier onlyBuyer(uint256 tradeId) {
        require(msg.sender == trades[tradeId].buyer, "Not buyer");
        _;
    }
    
    function lockFunds(
        address _buyer,
        address _token,
        uint256 _amount
    ) external {
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        
        tradeCounter++;
        trades[tradeCounter] = Trade({
            seller: msg.sender,
            buyer: _buyer,
            amount: _amount,
            token: _token,
            lockTime: block.timestamp,
            status: TradeStatus.LOCKED
        });
        
        emit FundsLocked(tradeCounter, msg.sender, _buyer, _amount);
    }
    
    function markFiatSent(uint256 tradeId) external onlyBuyer(tradeId) {
        require(trades[tradeId].status == TradeStatus.LOCKED, "Trade not locked");
        
        trades[tradeId].status = TradeStatus.FIAT_SENT;
        emit FiatMarkedSent(tradeId, msg.sender);
    }
    
    function releaseFunds(uint256 tradeId) external onlySeller(tradeId) {
        require(trades[tradeId].status == TradeStatus.FIAT_SENT, "Fiat not marked sent");
        
        trades[tradeId].status = TradeStatus.COMPLETED;
        IERC20(trades[tradeId].token).transfer(trades[tradeId].buyer, trades[tradeId].amount);
        
        emit FundsReleased(tradeId, trades[tradeId].seller, trades[tradeId].buyer);
    }
    
    function timeoutRefund(uint256 tradeId) external onlySeller(tradeId) {
        require(trades[tradeId].status == TradeStatus.LOCKED, "Trade not in locked state");
        require(block.timestamp >= trades[tradeId].lockTime + TIMEOUT_PERIOD, "Timeout not reached");
        
        trades[tradeId].status = TradeStatus.REFUNDED;
        IERC20(trades[tradeId].token).transfer(trades[tradeId].seller, trades[tradeId].amount);
        
        emit FundsRefunded(tradeId, trades[tradeId].seller);
    }
    
    function fiatNotReceived(uint256 tradeId) external onlySeller(tradeId) {
        require(trades[tradeId].status == TradeStatus.LOCKED, "Trade not in locked state");
        
        trades[tradeId].status = TradeStatus.REFUNDED;
        IERC20(trades[tradeId].token).transfer(trades[tradeId].seller, trades[tradeId].amount);
        
        emit FundsRefunded(tradeId, trades[tradeId].seller);
    }
}