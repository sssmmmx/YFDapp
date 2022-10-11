// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./YFRewards.sol";
import "./YFNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract NFTStaking is Ownable {
    
    uint256 public totalStaked;

    // 构建 stake token
    struct Stake {
        uint24 tokenId;
        uint48 timestamp;
        address owner;
    }

    event NFTStaked(address owner, uint256 tokenId, uint256 value);
    event NFTUnstaked(address owner, uint256 tokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    // reference to the Block NFT contract
    YFNFT nft;
    YFRewards token;

    // maps tokenId to stake
    mapping(uint256 => Stake) public vault; 

    constructor(YFNFT _nft, YFRewards _token) {
        nft = _nft;
        token = _token;
    }

    // 质押 多个NFT
    function stake(uint256[] calldata tokenIds) external {
        uint256 tokenId;
        totalStaked += tokenIds.length;
        for(uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "not your token");
            require(vault[tokenId].tokenId == 0, 'already staked');

            //使用 emit 关键字触发事件 Calldata是一个不可变的临时位置，用于存储函数参数，其行为主要类似于memory
            nft.safeTransferFrom(msg.sender, address(this), tokenId);
            emit NFTStaked(msg.sender, tokenId, block.timestamp);

            vault[tokenId] = Stake({
                owner: msg.sender,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    // 解除质押并提现 多个NFT
    function _unstakeMany(address account, uint256[] calldata tokenIds) internal {
        uint256 tokenId;
        totalStaked -= tokenIds.length;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == msg.sender, "not an owner");

            delete vault[tokenId];
            emit NFTUnstaked(account, tokenId, block.timestamp);
            nft.safeTransferFrom(address(this), account, tokenId);
        }
    }

    function claim(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, false);
    }

    function claimForAddress(address account, uint256[] calldata tokenIds) external {
      _claim(account, tokenIds, false);
    }

    function unstake(uint256[] calldata tokenIds) external {
      _claim(msg.sender, tokenIds, true);
    }

    function _claim(address account, uint256[] calldata tokenIds, bool _unstake) internal {
        uint256 tokenId;
        uint256 earned = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            require(staked.owner == account, "not an owner");

            uint256 stakedAt = staked.timestamp;
            earned += 100000 ether * (block.timestamp - stakedAt) / 1 days;
            vault[tokenId] = Stake({
                owner: account,
                tokenId: uint24(tokenId),
                timestamp: uint48(block.timestamp)
            });
        }
        
        if (earned > 0) {
            earned = earned / 10;
            token.mint(account,earned);
        }
        if (_unstake) {
            _unstakeMany(account, tokenIds);
        }
        emit Claimed(account, earned);

    }

    function earningInfo(uint256[] calldata tokenIds) external view returns (uint256[2] memory info) {
        uint256 tokenId;
        uint256 totalScore = 0;
        uint256 earned = 0;

        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            Stake memory staked = vault[tokenId];
            uint256 stakedAt = staked.timestamp;
            earned += 100000 ether * (block.timestamp - stakedAt) / 1 days;
            uint256 earnRatePerSecond = totalScore * 1 ether / 1 days;
            earnRatePerSecond = earnRatePerSecond / 100000;

        // earned, earnRatePerSecond
        return [earned, earnRatePerSecond];
    }
    }