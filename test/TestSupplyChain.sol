pragma solidity ^0.4.13;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

/* Contract to imitate external Seller */
contract Seller {

  // SupplyChain contract address
  SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());

  function addSellerItem(string _item, uint _price) public {
    supplychain.addItem(_item, _price);
  }

  function markItemShipped(uint _sku) public returns (bool) {
    return address(supplychain).call(abi.encodeWithSignature("shipItem(uint256)"), _sku);
  }

  function() public payable {
  }
}

/* Contract to imitate external Seller */
contract Buyer {

  SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());

  // return false on exception
  function createBuyerOffer(uint256 _sku, uint _price) public returns (bool) {
    return address(supplychain).call.value(_price)(abi.encodeWithSignature("buyItem(uint256)"), _sku);
  }

  // return false on exception
  function markItemReceived(uint _sku) public returns (bool) {
    return address(supplychain).call(abi.encodeWithSignature("receiveItem(uint256)"), _sku);
  }

  // accept Ether
  function() public payable {
  }
}


contract TestSupplyChain {
  // give contract some ether
  uint public initialBalance = 50 ether;

  // external contract addresses
  SupplyChain supplychain = SupplyChain(DeployedAddresses.SupplyChain());
  Seller selleraddress;
  Buyer buyeraddress;

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
    // create Seller
    selleraddress = createSeller();
    // offer Item for Sale
    selleraddress.addSellerItem('SaleItem', 5);
    // check details
    fetchItem(0);
    Assert.equal('SaleItem', name, 'Wrong Item name');
    Assert.equal(5, price, 'Wrong Price');
    Assert.equal(selleraddress, seller, 'Wrong Seller address');
    Assert.equal(0, state, 'Wrong State (not ForSale)');
  }

  // Test Seller can't ship an item that is not sold
  function testShipNotSold() public
  {
    bool result = selleraddress.markItemShipped(1);
    Assert.isFalse(result, "ShipNotSold failed to throw exception");
    fetchItem(1);
    Assert.equal(0, state, 'State should still be 0 (ForSale)');
  }

  // Test Buyer trying to Purchase the Item for too little
  function testBuyNotEnoughCash() public
  {
    // create a buyer
    buyeraddress = createBuyer();
    // make sure buyer has either
    address(buyeraddress).transfer(20);
    // try to purchase for price-1
    bool result = buyeraddress.createBuyerOffer(1, price-1);
    // check details
    Assert.isFalse(result, "NotEnoughCash failed to throw exception");
    fetchItem(0);
    Assert.equal(0, state, 'State should still be 0 (ForSale)');
    Assert.equal(address(0), buyer, 'Buyer should still be empty');
  }

  // Test Buyer Purchase with sufficient offer
  function testBuyItem() public
  {
    bool result = buyeraddress.createBuyerOffer(0, 5);
    Assert.isTrue(result, "testBuyItem threw exception");
    fetchItem(0);
    Assert.equal('SaleItem', name, 'Wrong Item');
    Assert.equal(buyeraddress, buyer, 'Wrong Buyer address');
    Assert.equal(1, state, 'Wrong State (not Sold)');
  }

  // Test trying to purchase an item that is not for Sale (already sold)
  function testItemAlreadySold() public
  {
    bool result = buyeraddress.createBuyerOffer(0, 5);   // Sku 0 already purchased
    Assert.isFalse(result, "AlreadySold failed to throw exception");
  }

  // Test non-seller trying to mark a sold Item as shipped
  function testShipNotSeller() public
  {
    bool result = address(supplychain).call(abi.encodeWithSignature("shipItem(uint256)"), 2);
    Assert.isFalse(result, "ShipNotSeller failed to throw exception");
  }

  // Test Buyer trying to receive an item that is not yet shipped
  function testReceiveNotShipped() public
  {
    bool result = buyeraddress.markItemReceived(1);
    Assert.isFalse(result, "ShipNotSold failed to throw exception");
    fetchItem(1);
    Assert.equal(0, state, 'State should still be 0 (ForSale)');
  }

  // Test that Seller can mark a sold Item shipped (
  function testShipItem() public
  {
    bool result = selleraddress.markItemShipped(0);
    Assert.isTrue(result, "testShipItem threw exception");
    fetchItem(0);
    Assert.equal(2, state, 'Wrong State (not Shipped)');
  }

  // Test non-buyer trying to mark a shipped Item as received
  function testReceiveNotBuyer() public
  {
    bool result = address(supplychain).call(abi.encodeWithSignature("receiveItem(uint256)"), 2);
    Assert.isFalse(result, "ReceiveNotBuyer failed to throw exception");
  }

  // Test that Buyer can mark a shipped Item received
  function testReceiveItem() public
  {
    bool result = buyeraddress.markItemReceived(0);
    Assert.isTrue(result, "testShipItem threw exception");
    fetchItem(0);
    Assert.equal(3, state, 'Wrong State (not Received)');
  }

}
