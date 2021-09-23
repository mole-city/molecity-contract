pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MBep20.sol";
import "./EIP20Interface.sol";

//Used to test the value of the currency, but not in the online loan agreement

contract SimplePriceOracle is PriceOracle {
    mapping(string => uint) public price;
    mapping(address => uint) prices;

    function setPrice(string memory symbol, uint _price) public {
       price[symbol] = _price;
    }

    event PricePosted(address asset, uint previousPriceMantissa, uint requestedPriceMantissa, uint newPriceMantissa);

    function getUnderlyingPrice(MToken mToken) public view returns (uint) {
        if (compareStrings(mToken.symbol(), "mETH")) {
            return price["ETH"];
        } else {
            return prices[address(MBep20(address(mToken)).underlying())];
        }
    }

    function setUnderlyingPrice(MToken mToken, uint underlyingPriceMantissa) public {
        if (compareStrings(mToken.symbol(), "mETH")) {
            price["ETH"] = underlyingPriceMantissa;
            emit PricePosted(address(0), price["ETH"], underlyingPriceMantissa, underlyingPriceMantissa);
        } else {
            address asset = address(MBep20(address(mToken)).underlying());
            price[EIP20Interface(asset).symbol()] = underlyingPriceMantissa;
            prices[asset] = underlyingPriceMantissa;
            emit PricePosted(asset, prices[asset], underlyingPriceMantissa, underlyingPriceMantissa);
        }
    }

    function setDirectPrice(address asset, uint _price) public {
        price[EIP20Interface(asset).symbol()] = _price;
        prices[asset] = _price;
        emit PricePosted(asset, prices[asset], _price, _price);
    }

    // v1 price oracle interface for use as backing of proxy
    function assetPrices(address asset) external view returns (uint) {
        return prices[asset];
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }
}
