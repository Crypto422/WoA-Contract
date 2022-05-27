// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ScammerNFT is ERC721Enumerable, Ownable {
    using Strings for uint256;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseURI;
    string public baseExtension = ".json";
    string public notRevealedUri;
    uint256 public maxSupply = 1000;
    uint256 public maxMintAmount = 10;
    uint256 public nftPerAddresslimit = 3;
    bool public paused = false;
    bool public revealed = true;
    bool public onlyWhitelisted = false;
    address[] public whitelistedAddresses;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri)
        ERC721("Kick Scammers", "KSCM")
    {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused);
        uint256 totalMinted = _tokenIds.current();

        require(
            totalMinted.add(_mintAmount) <= maxSupply,
            "Not enough NFTs left!"
        );
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmount,
            "Cannot mint specified number of NFTs."
        );

        if (msg.sender != owner()) {
            if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerTokenCount = balanceOf(msg.sender);
                require(ownerTokenCount < nftPerAddresslimit);
            }
            //   require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint256 newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function reveal() public onlyOwner {
        revealed = true;
    }

    function setNftPerAddresslimit(uint256 _limit) public onlyOwner {
        nftPerAddresslimit = _limit;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setmaxSupply(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getERC20TokenBalance(IERC20 token)
        external
        view
        returns (uint256)
    {
        return token.balanceOf(address(this));
    }

    function withdraw() public onlyOwner {
        require(address(this).balance != 0, "contract has no balance");
        payable(_msgSender()).transfer(address(this).balance);
    }

    /**
     * @dev sends the full balance of the given token held by this contract to the caller
     */
    function withdraw(IERC20 token) public onlyOwner {
        require(
            token.balanceOf(address(this)) != 0,
            "contract has no balance of token"
        );
        token.safeTransfer(_msgSender(), token.balanceOf(address(this)));
    }
}
