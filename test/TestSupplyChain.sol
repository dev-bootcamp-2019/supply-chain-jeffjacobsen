pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract Seller {
  function addSellerItem(string _item, uint _price) public {
    SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());
    supplychain.addItem(_item, _price);
  }
  function() public payable {
  }
}

contract Buyer {
  function createBuyerOffer(uint _sku, uint _price) public {
    SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());
    supplychain.buyItem.value(_price)(_sku);
  }
  function() public payable {
  }
}


contract TestSupplyChain {
  // give contract some ether
  uint public initialBalance = 10 ether;

  SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());
  Seller selleraddress;
  Buyer buyeraddress;

  enum State { ForSale, Sold, Shipped, Received }

  string name;
  uint sku;
  uint price;
  uint state;
  address seller;
  address buyer;

  function fetchItem(uint _sku) internal {
    (name, sku, price, state, seller, buyer) = supplychain.fetchItem(_sku);
  }

  // Create Seller Contract and return address
  function createSeller() internal returns (Seller)
  {
    return new Seller();
  }

  // Create Buyer Contract and return address
  function createBuyer() internal returns (Buyer)
  {
    return new Buyer();
  }


  // Test Creating a Seller and offer an Item for Sale
  function testCreateItemForSale() public
  {
    selleraddress = createSeller();
    selleraddress.addSellerItem('SaleItem', 5);
    fetchItem(0);
    Assert.equal('SaleItem', name, 'Wrong Item name');
    Assert.equal(5, price, 'Wrong Price');
    Assert.equal(selleraddress, seller, 'Wrong Seller address');
    Assert.equal(0, state, 'Wrong State (not ForSale)');
  }

  // Test Creating a Buyer to Purchase the Item from Seller
  function testBuyItem() public
  {
    buyeraddress = createBuyer();
    // make sure buyer has either
    address(buyeraddress).transfer(10);
    buyeraddress.createBuyerOffer(0, 5);
    fetchItem(0);
    Assert.equal('SaleItem', name, 'Wrong Item');
    Assert.equal(buyeraddress, buyer, 'Wrong Buyer address');
    Assert.equal(1, state, 'Wrong State (not Sold)');
  }



    // buyItem

    // test for failure if user does not send enough funds
    // test for purchasing an item that is not for Sale


    // shipItem

    // test for calls that are made by not the seller
    // test for trying to ship an item that is not marked Sold

    // receiveItem

    // test calling the function from an address that is not the buyer
    // test calling the function on an item not marked Shipped


}
