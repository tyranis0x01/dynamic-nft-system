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

    // NFT State Management
    struct NFTState {
        uint256 lastWeatherUpdate;
        uint256 lastTimeUpdate;
        uint256 userActionCount;
        string currentWeather;
        string currentTimeOfDay;
        address owner;
        uint256 createdAt;
    }

    // Storage
    mapping(uint256 => NFTState) public nftStates;
    mapping(address => uint256[]) public userTokens;

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner);
    event NFTUpdated(uint256 indexed tokenId, string updateType, string newValue);
    event OracleUpdated(address indexed oracle, string oracleType);
    event UserAction(uint256 indexed tokenId, address indexed user, string action);

    // Constants
    uint256 public constant UPDATE_INTERVAL = 1 hours;
    uint256 public constant MAX_SUPPLY = 10000;

    constructor(address _weatherOracle, address _timeOracle, address _metadataRenderer)
        ERC721("Dynamic Weather NFT", "DYNFT")
        Ownable(msg.sender)
    {
        weatherOracle = IDataOracle(_weatherOracle);
        timeOracle = IDataOracle(_timeOracle);
        metadataRenderer = IMetadataRenderer(_metadataRenderer);
    }

    /**
     * @dev Mint a new dynamic NFT
     */
    function mint(address to) public onlyOwner returns (uint256) {
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;

        _safeMint(to, tokenId);

        // Initialize NFT state
        nftStates[tokenId] = NFTState({
            lastWeatherUpdate: block.timestamp,
            lastTimeUpdate: block.timestamp,
            userActionCount: 0,
            currentWeather: "sunny",
            currentTimeOfDay: _getCurrentTimeOfDay(),
            owner: to,
            createdAt: block.timestamp
        });

        userTokens[to].push(tokenId);

        emit NFTMinted(tokenId, to);
        return tokenId;
    }

    /**
     * @dev Update NFT based on weather data
     */
    function updateWeather(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(block.timestamp >= nftStates[tokenId].lastWeatherUpdate + UPDATE_INTERVAL, "Too early to update");

        string memory newWeather = weatherOracle.getData();
        nftStates[tokenId].currentWeather = newWeather;
        nftStates[tokenId].lastWeatherUpdate = block.timestamp;

        emit NFTUpdated(tokenId, "weather", newWeather);
    }

    /**
     * @dev Update NFT based on time of day
     */
    function updateTimeOfDay(uint256 tokenId) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(block.timestamp >= nftStates[tokenId].lastTimeUpdate + UPDATE_INTERVAL, "Too early to update");

        string memory newTimeOfDay = _getCurrentTimeOfDay();
        nftStates[tokenId].currentTimeOfDay = newTimeOfDay;
        nftStates[tokenId].lastTimeUpdate = block.timestamp;

        emit NFTUpdated(tokenId, "timeOfDay", newTimeOfDay);
    }

    /**
     * @dev Record user action that affects NFT
     */
    function performUserAction(uint256 tokenId, string calldata action) external {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not token owner");

        nftStates[tokenId].userActionCount++;

        emit UserAction(tokenId, msg.sender, action);
        emit NFTUpdated(tokenId, "userAction", Strings.toString(nftStates[tokenId].userActionCount));
    }

    /**
     * @dev Get current time of day based on block timestamp
     */
    function _getCurrentTimeOfDay() internal view returns (string memory) {
        uint256 hour = (block.timestamp / 3600) % 24;

        if (hour >= 6 && hour < 12) return "morning";
        if (hour >= 12 && hour < 18) return "afternoon";
        if (hour >= 18 && hour < 22) return "evening";
        return "night";
    }

    /**
     * @dev Override tokenURI to return dynamic metadata
     */
        function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        NFTState memory state = nftStates[tokenId];
        IMetadataRenderer.NFTState memory rendererState = IMetadataRenderer.NFTState({
            lastWeatherUpdate: state.lastWeatherUpdate,
            lastTimeUpdate: state.lastTimeUpdate,
            userActionCount: state.userActionCount,
            currentWeather: state.currentWeather,
            currentTimeOfDay: state.currentTimeOfDay,
            owner: state.owner,
            createdAt: state.createdAt
        });
        return metadataRenderer.renderMetadata(tokenId, rendererState);
    }
}
