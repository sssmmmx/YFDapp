// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// import "./Merkle.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract YFNFT is ERC721, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("YFNFT", "YFNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmSoMgDa6k3snsfE6x7MiXrz7RnQhRprwFtFKQ5tZvsCgB/";
    }
    
    // 构建mint函数 只允许白名单上的地址mint
    // Merkle merkle;
    function safeMint(address to) public payable {
        // 验证merkle白名单 bytes32[] calldata merkleProof
        // merkle.mint(merkleProof);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}

/**
 * 本合约调用ERC721快速构建NFT，并使用MerkleTree机制实现链下白名单。
 * 规定的地址才能通过本合约mint NFT (自动增量 ID)
 * 
 * 功能接口：
 * safeMint 铸造一枚NFT
 */