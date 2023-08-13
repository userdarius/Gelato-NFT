// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Consumer.sol";
import "./Inbox.sol";
import "./Base64.sol";
// 0x697b6e2a2E975b9469d895c605Cc3262eCeCA416,0x7c97b48e923283b312fd5d378554d8b9e8fe6855
contract CircleNFT is ERC721Enumerable, GelatoVRFConsumer {
    using Strings for uint256;
    using Base64 for bytes; // Use the Base64 library for bytes type
    uint256 public latestRandomness;
    GelatoVRFInbox public inbox;
    address public dedicatedMsgSender;
    uint256 public _tokenIdCounter;

    // Mapping from token ID to SVG data
    mapping(uint256 => string) private _svgData;

    constructor(GelatoVRFInbox _inbox, address _dedicatedMsgSender)
        ERC721("CircleNFT", "CNFT")
    {
        inbox = _inbox;
        dedicatedMsgSender = _dedicatedMsgSender;
    }

    function fullfillRandomness(uint256 randomness, bytes calldata) external {
        require(msg.sender == dedicatedMsgSender, "The sender is not the VRF");
        latestRandomness = randomness;
        
        uint256 tokenId = _tokenIdCounter;
        _mint(msg.sender, tokenId);
        _tokenIdCounter += 1;

        // Create random radius and color for the SVG
        uint256 radius = randomRadius(latestRandomness);
        string memory color = randomColor(latestRandomness);

        // Create SVG data
        string memory svg = createSVG(radius, color);
        _svgData[tokenId] = svg;
    }

    function mintCircle() public {
        inbox.requestRandomness(this, "");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory svg = _svgData[tokenId];
        return string(abi.encodePacked("data:image/svg+xml;utf8,", svg));
    }

    function randomRadius(uint256 randomness) private pure returns (uint256) {
        return
            (uint256(keccak256(abi.encodePacked(randomness))) %
                50) + 10; // A random value between 10 and 60
    }

    function randomColor(uint256 randomness) private pure returns (string memory) {
        string[10] memory colors = [
            "red",
            "green",
            "blue",
            "yellow",
            "pink",
            "purple",
            "orange",
            "cyan",
            "magenta",
            "black"
        ];
        uint256 index = uint256(
            keccak256(abi.encodePacked(randomness))
        ) % 10;
        return colors[index];
    }

    function createSVG(uint256 radius, string memory color)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><circle cx="100" cy="100" r="',
                    radius.toString(),
                    '" fill="',
                    color,
                    '"/></svg>'
                )
            );
    }
}
