// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//the rarible dependency files are needed to setup sales royalties on Rarible
import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "./@rarible/royalties/contracts/LibPart.sol";
import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";


contract NFTMarketPlace is ReentrancyGuard, RoyaltiesV2Impl  {
    uint256 marketFees = 0.10 ether;
    address payable owner;

    using Counters for Counters.Counter;
    Counters.Counter private itemId;
    Counters.Counter private itemsSold;

    constructor() {
        owner = payable(msg.sender);
    }

    struct NftMerketItem {
        address nftContract;
        uint256 id;
        uint256 tokenId;
        address payable owner;
        address payable seller;
        uint256 price;
        bool sold;
    }

    event NftMerketItemCreated(
        address indexed nftContract,
        uint256 indexed id,
        uint256 tokenId,
        address owner,
        address seller,
        uint256 price,
        bool sold
    );

    function gettheMarketFees() public view returns (uint256) {
        return marketFees;
    }

    ///////////////////////////////////
    mapping(uint256 => NftMerketItem) private idForMarketItem;

    ///////////////////////////////////
    function createItemForSale(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price should be moreThan 1");
        require(tokenId > 0, "token Id should be moreThan 1");
        require(msg.value == marketFees, "The Market Fees is 0.010 Ether");
        require(nftContract != address(0), "address should not be equal 0x0");
        itemId.increment();
        uint256 id = itemId.current();

        idForMarketItem[id] = NftMerketItem(
            nftContract,
            id,
            tokenId,
            payable(address(0)),
            payable(msg.sender),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit NftMerketItemCreated(
            nftContract,
            id,
            tokenId,
            address(0),
            msg.sender,
            price,
            false
        );
    }

    //Create Maket

    function createMarketForSale(address nftContract, uint256 nftItemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idForMarketItem[nftItemId].price;
        uint256 tokenId = idForMarketItem[nftItemId].tokenId;

        require(msg.value == price, "should buy the price of item");
        idForMarketItem[nftItemId].seller.transfer(msg.value);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId); //buy
        idForMarketItem[nftItemId].owner = payable(msg.sender);
        idForMarketItem[nftItemId].sold = true;
        itemsSold.increment();
        payable(owner).transfer(marketFees);
    }
    //configure royalties for Rariable
    function setRoyalties(
        uint256 _tokenId,
        address payable _royaltiesRecipientAddress,
        uint96 _percentageBasisPoints
    ) public payable nonReentrant {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }

    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        //use the same royalties that were saved for Rariable
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (
                _royalties[0].account,
                (_salePrice * _royalties[0].value) / 10000
            );
        }
        return (address(0), 0);
    }

    //My items => sold,not sold,buy

    function getMyItemCreated() public view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount = 0; //10
        uint256 myCurrentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].seller == msg.sender) {
                myItemCount += 1;
            }
        }
        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].seller == msg.sender) {
                //[1,2,3,4,5]
                uint256 currentId = i + 1;
                NftMerketItem storage currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }

        return nftItems;
    }

    //Create My purchased Nft Item

    function getMyNFTPurchased() public view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount = 0; //10
        uint256 myCurrentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == msg.sender) {
                myItemCount += 1;
            }
        }

        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == msg.sender) {
                //[1,2,3,4,5]
                uint256 currentId = i + 1;
                NftMerketItem storage currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }

        return nftItems;
    }

    //Fetch  all unsold nft items
    function getAllUnsoldItems() public view returns (NftMerketItem[] memory) {
        uint256 totalItemCount = itemId.current();
        uint256 myItemCount = itemId.current() - itemsSold.current();
        uint256 myCurrentIndex = 0;

        NftMerketItem[] memory nftItems = new NftMerketItem[](myItemCount); //list[3]
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idForMarketItem[i + 1].owner == address(0)) {
                //[1,2,3,4,5]
                uint256 currentId = i + 1;
                NftMerketItem storage currentItem = idForMarketItem[currentId];
                nftItems[myCurrentIndex] = currentItem;
                myCurrentIndex += 1;
            }
        }

        return nftItems;
    }
}
