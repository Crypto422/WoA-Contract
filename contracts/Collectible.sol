// SPDX-License-Identifier: MIT

// Amended by Wolf of AVAX
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Collectible is ERC721Enumerable, Ownable {
  using SafeMath for uint256;
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 1 ether;
  uint256 public maxSupply = 8888;
  uint256 public maxMintAmount = 20;
  bool public paused = true;
  bool public revealed = false;
  string public notRevealedUri;
  uint256 public percentagePerMintToMinters = 20;
  uint256 public percentageRoyalty = 15;
  uint256 public percentageRoyaltyPerHolder = 85;
  uint256 public percentageRoyaltyPerCreator = 15;
  uint256 public salesCount = 0;

  mapping (address => uint256[]) public tokenIdsMintedByCreator;

  mapping (uint256 => uint256) public runningMintBalance;
  mapping (uint256 => uint256) public runningSaleBalanceForHolders;
  mapping (uint256 => uint256) public runningSaleBalanceForCreator;

  mapping (uint256 => uint256) public lastClaimedMintIndexByTokenId;
  mapping (uint256 => uint256) public lastClaimedSaleIndexForHoldersByTokenId;
  mapping (uint256 => uint256) public lastClaimedSaleIndexForCreatorsByTokenId;

  event ItemMinted(uint256 tokenId, address creator);

  constructor() ERC721("Testing123", "T123") {
    setBaseURI("ipfs://QmRzw86jC5g1CFEPiSUipyXf6EtJ6Uz1CjevEnjirdJStc/");
    setNotRevealedURI("ipfs://QmY1k4iWEkLMNequ1dzrxdnghPA2JTq4GLUNuerupwZH7a/hidden.json");
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
      payable(msg.sender).transfer(msg.value - cost * _mintAmount);
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 itemId = supply + i;
      _safeMint(msg.sender, itemId);
      if (itemId > 1) {
        runningMintBalance[itemId] = runningMintBalance[itemId-1].add(cost.mul(percentagePerMintToMinters).div(100).div(itemId-1));
      } else {
        runningMintBalance[itemId] = 0;
      }
      lastClaimedMintIndexByTokenId[itemId] = itemId;
      lastClaimedSaleIndexForHoldersByTokenId[itemId] = itemId;
      lastClaimedSaleIndexForCreatorsByTokenId[itemId] = itemId;
      tokenIdsMintedByCreator[msg.sender].push(itemId);
      emit ItemMinted(itemId, msg.sender);
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension)) : "";
  }

  // public getter
  function claimableRewards()
    external
    view
    returns (uint256)
  {
    uint256 supply = totalSupply();
    uint256 senderTokenCount = balanceOf(msg.sender);
    uint256 claimableBalance = 0;

    for (uint256 i; i < senderTokenCount; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
      claimableBalance = claimableBalance.add(runningMintBalance[supply]).sub(runningMintBalance[lastClaimedMintIndexByTokenId[tokenId]]); // for minters
      claimableBalance = claimableBalance.add(runningSaleBalanceForHolders[salesCount]).sub(runningSaleBalanceForHolders[lastClaimedSaleIndexForHoldersByTokenId[tokenId]]); // for holders per sale
    }

    for (uint256 i; i < tokenIdsMintedByCreator[msg.sender].length; i++) {
      uint256 tokenId = tokenIdsMintedByCreator[msg.sender][i];
      claimableBalance = claimableBalance.add(runningSaleBalanceForCreator[salesCount]).sub(runningSaleBalanceForCreator[lastClaimedSaleIndexForCreatorsByTokenId[tokenId]]); // for creators per sale
    }
    
    return claimableBalance;
  }

  function claimRewards() external payable {
    uint256 supply = totalSupply();
    uint256 senderTokenCount = balanceOf(msg.sender);
    uint256 claimableBalance = 0;

    for (uint256 i; i < senderTokenCount; i++) {
      uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
      claimableBalance = claimableBalance.add(runningMintBalance[supply]).sub(runningMintBalance[lastClaimedMintIndexByTokenId[tokenId]]); // for minters
      lastClaimedMintIndexByTokenId[tokenId] = supply;
      claimableBalance = claimableBalance.add(runningSaleBalanceForHolders[salesCount]).sub(runningSaleBalanceForHolders[lastClaimedSaleIndexForHoldersByTokenId[tokenId]]); // for holders per sale
      lastClaimedSaleIndexForHoldersByTokenId[tokenId] = salesCount;
    }

    for (uint256 i; i < tokenIdsMintedByCreator[msg.sender].length; i++) {
      uint256 tokenId = tokenIdsMintedByCreator[msg.sender][i];
      claimableBalance = claimableBalance.add(runningSaleBalanceForCreator[salesCount]).sub(runningSaleBalanceForCreator[lastClaimedSaleIndexForCreatorsByTokenId[tokenId]]); // for creators per sale
      lastClaimedSaleIndexForCreatorsByTokenId[tokenId] = salesCount;
    }

    (bool success, ) = payable(msg.sender).call{value: claimableBalance}("");
    require(success);
  }

  //only owner
  function setRevealed(bool _state) external onlyOwner {
    revealed = _state;
  }
  
  function setCost(uint256 _newCost) external onlyOwner() {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner() {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function setPercentagePerMintToMinters(uint256 _percentagePerMintToMinters) external onlyOwner {
    percentagePerMintToMinters = _percentagePerMintToMinters;
  }

  function setPercentageRoyalty(uint256 _percentageRoyalty) external onlyOwner {
    percentageRoyalty = _percentageRoyalty;
  }

  function setPercentageRoyaltyPerHolder(uint256 _percentageRoyaltyPerHolder) external onlyOwner {
    percentageRoyaltyPerHolder = _percentageRoyaltyPerHolder;
  }

  function setPercentageRoyaltyPerCreator(uint256 _percentageRoyaltyPerCreator) external onlyOwner {
    percentageRoyaltyPerCreator = _percentageRoyaltyPerCreator;
  }

  function setPaused(bool _state) external onlyOwner {
    paused = _state;
  }
 
  function withdraw(uint256 _amount) external payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: _amount}("");
    require(success);
  }
}