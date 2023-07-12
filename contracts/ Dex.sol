pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./wallet.sol";

contract Dex is wallet{

    using SafeMath for uint256;
   
   enum Side{
    BUY,
    SELL
   }

   struct Order {
    uint id;
    address trader; 
    Side side;
    bytes32 ticker;
    uint amount;
    uint price;
    uint filled;
   }

   uint public nextOrderId = 0;

   mapping(bytes32 => mapping(uint => Order[])) public orderBook;

   function getOrderBook(bytes32 ticker, Side side) view public returns (Order [] memory){
       return orderBook[ticker][uint(side)];
   }
   
  function createLimitOrder(Side side, bytes32 ticker, uint amount, uint price) public{
    if(side == Side.BUY){
        require(balances[msg.sender]["ETH"] >= amount.mul(price));
    }
     else if(side == Side.BUY){
        require(balances[msg.sender][ticker] >= amount);
    }

    Order[] storage orders = orderBook[ticker][uint(side)];  
       orders.push(
        Order(nextOrderId , msg.sender, side, ticker, amount,price, 0)
        );

        //Bubble sort
       // Order memory temp;
        uint i = orders.length >0 ? orders.length -1 : 0;
        if(side == Side.BUY) {
          /* for(uint i =0; i< orders.length; i++){
            for(uint j = 0; j < orders.length-1; j++){
                 
                 if(orders[i].amount < orders[j+1].amount){
                  temp = orders[i];
                  orders[i]=orders[j+1];
                  orders[j+1]=temp;
                 }
            }*/
           
           while(i>0){

            if(orders[i-1].price > orders[i].price){
              break;
            }
            Order memory orderToMove = orders[i-1];
            orders[i-1]=orders[i];
            orders[i]=orderToMove;
            i--;
           }


           }
        
        else if(side == Side.SELL) {
             /*for(uint i =0; i< orders.length; i++){
                for(uint j = 0; j < orders.length-1; j++){
                 
                 if(orders[i].amount > orders[j+1].amount){
                  temp = orders[i];
                  orders[i]=orders[j+1];
                  orders[j+1]=temp;
                 }
               }
             }*/
             while(i>0){
            if(orders[i-1].price < orders[i].price){
              break;
            }
            Order memory orderToMove = orders[i-1];
            orders[i-1]=orders[i];
            orders[i]=orderToMove;
            i--;
           }
        }

        nextOrderId++;
  }
   
   function createMarketOrder(Side side, bytes32 ticker,  uint amount) public {

     if(side == Side.SELL){
     require(balances[msg.sender][ticker] >= amount,"Insufficient balance");
     }
    uint orderBookSide;
    if(side == Side.BUY){
       orderBookSide = 1;
    }
    else if(side == Side.SELL){
       orderBookSide = 0;
    }
    Order[] storage orders = orderBook[ticker][orderBookSide];  //gets the opposite of the market order request.

    uint totalFilled=0;
    for(uint256 i=0; i<orders.length && totalFilled < amount; i++){
      uint leftToFill = amount.sub(totalFilled);
      uint availableToFill = orders[i].amount.sub(orders[i].filled);
      uint filled = 0;
      if(availableToFill > leftToFill){
        filled = leftToFill; ////Fill the entire market order
      }
      else{
        filled = availableToFill; ////Fill as much as is available in order[i]
      }

      totalFilled = totalFilled.add(filled);
      orders[i].filled = orders[i].filled.add(filled);
      uint cost = filled.mul(orders[i].price);

      if(side == Side.BUY){
        //verif that the buyer has enough eith to cover the purchase
        require(balances[msg.sender]["ETH"] >= filled.mul(orders[i].price));
        //msg.sendeer is buyer
        balances[msg.sender][ticker] = balances[msg.sender][ticker].add(filled);
        balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].sub(cost);

        balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].sub(filled);
        balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].add(cost);
      }
      else if(side == Side.SELL){
       // msg.sender is the seller
         balances[msg.sender][ticker] = balances[msg.sender][ticker].sub(filled);
         balances[msg.sender]["ETH"] = balances[msg.sender]["ETH"].add(cost);
 
        balances[orders[i].trader][ticker] = balances[orders[i].trader][ticker].add(filled);
        balances[orders[i].trader]["ETH"] = balances[orders[i].trader]["ETH"].sub(cost);
      }

        


    }
    //Loop through the orderBook and remove 100% filled order

    while(orders.length > 0 && orders[0].filled == orders[0].amount){
      //remove the top element in the orders array by overwritting every element
      //with the next element in the order list
      for(uint256 i=0; i< orders.length-1; i++){
        orders[i]= orders[(i+1)];
      }
      orders.pop();
    }
   }

}
