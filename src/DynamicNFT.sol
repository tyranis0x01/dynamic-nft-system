// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IDataOracle.sol";
import "./interfaces/IMetadataRenderer.sol";

/**
 * @title DynamicNFT
 * @dev NFT contract that changes metadata based on external data sources
 */
contract DynamicNFT is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _tokenIdCounter;

    // Core interfaces
    IDataOracle public weatherOracle;
    IDataOracle public timeOracle;
    IMetadataRenderer public metadataRenderer;

    constructor(address _weatherOracle, address _timeOracle, address _metadataRenderer)
        ERC721("Dynamic Weather NFT", "DYNFT")
        Ownable(msg.sender)
    {
        weatherOracle = IDataOracle(_weatherOracle);
        timeOracle = IDataOracle(_timeOracle);
        metadataRenderer = IMetadataRenderer(_metadataRenderer);
    }
}
