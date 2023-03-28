// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IKaiKongsNFT.sol";
import "./interfaces/IKaiKongsFactory.sol";

contract KaiKongsMarketplace is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IERC721ReceiverUpgradeable,
    UUPSUpgradeable
{
    IKaiKongsFactory private kaiKongsFactory;

    uint256 private platformFee;
    address private feeRecipient;

    struct ListNFT {
        address nft;
        uint256 tokenId;
        address seller;
        uint256 price;
        uint256 date;
        bool sold;
    }

    struct OfferNFT {
        address nft;
        uint256 tokenId;
        address offerer;
        uint256 offerPrice;
        uint256 date;
        bool accepted;
    }

    struct AuctionNFT {
        address nft;
        uint256 tokenId;
        address creator;
        uint256 initialPrice;
        uint256 minBid;
        uint256 startTime;
        uint256 endTime;
        address lastBidder;
        uint256 heighestBid;
        address winner;
        bool success;
    }

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListNFT)) private listNfts;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferNFT)))
        private offerNfts;

    // nft => tokenId => acuton struct
    mapping(address => mapping(uint256 => AuctionNFT)) private auctionNfts;

    // auciton index => bidding counts => bidder address => bid price
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private bidPrices;

    // events
    event ListedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        uint256 date,
        address indexed seller
    );
    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address indexed buyer
    );
    event OfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice,
        uint256 date,
        address indexed offerer
    );
    event CanceledOfferredNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice,
        address indexed offerer
    );
    event AcceptedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );
    event CreatedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 price,
        uint256 minBid,
        uint256 startTime,
        uint256 endTime,
        address indexed creator
    );
    event PlacedBid(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 bidPrice,
        address indexed bidder
    );

    event ResultedAuction(
        address indexed nft,
        uint256 indexed tokenId,
        address creator,
        address indexed winner,
        uint256 price,
        address caller
    );

    function _authorizeUpgrade(address) internal override onlyOwner {}

    function initialize(
        uint256 _platformFee,
        address _feeRecipient,
        IKaiKongsFactory _kaikongsFactory
    ) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        kaiKongsFactory = _kaikongsFactory;
    }

    modifier isKaiKongsNFT(address _nft) {
        require(kaiKongsFactory.isKaiKongsNFT(_nft), "not KaiKongs NFT");
        _;
    }

    modifier isListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(
            listedNFT.seller != address(0) && !listedNFT.sold,
            "not listed"
        );
        _;
    }

    modifier isNotListedNFT(address _nft, uint256 _tokenId) {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(
            listedNFT.seller == address(0) || listedNFT.sold,
            "already listed"
        );
        _;
    }

    modifier isAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft != address(0) && !auction.success,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft == address(0) || auction.success,
            "auction already created"
        );
        _;
    }

    modifier isOfferredNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    ) {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][_offerer];
        require(
            offer.offerPrice > 0 && offer.offerer != address(0),
            "not offerred nft"
        );
        _;
    }

    /**
     * @notice put the NFT on marketplace
     * @param _nft specified NFT collection address
     * @param _tokenId specified NFT id to sell
     * @param _price the price of NFT
     */
    function createSell(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        address _seller
    ) external isKaiKongsNFT(_nft) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        nft.transferFrom(msg.sender, address(this), _tokenId);

        listNfts[_nft][_tokenId] = ListNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: _seller,
            price: _price,
            date: block.timestamp,
            sold: false
        });

        emit ListedNFT(_nft, _tokenId, _price, block.timestamp, _seller);
    }

    /**
     * @notice cancel listed NFT from marketplace
     * @param _nft NFT collection address to sell
     * @param _tokenId specified NFT id to sell
     */
    function cancelListedNFT(
        address _nft,
        uint256 _tokenId
    ) external isListedNFT(_nft, _tokenId) {
        ListNFT memory listedNFT = listNfts[_nft][_tokenId];
        require(listedNFT.seller == msg.sender, "not listed owner");
        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        delete listNfts[_nft][_tokenId];
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nfts a list of NFT collection addresses to buy
     * @param _tokenIds a list of specified NFT ids to buy
     */
    function bulkBuy(
        address[] memory _nfts,
        uint256[] memory _tokenIds
    ) external payable {
        require(
            _nfts.length == _tokenIds.length,
            "The length of ids and nfts should be equal"
        );

        for (uint256 i = 0; i < _nfts.length; i++) {
            ListNFT memory listedNft = listNfts[_nfts[i]][_tokenIds[i]];
            this.buy{value: listedNft.price}(_nfts[i], _tokenIds[i]);
        }
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nft NFT collection address to buy
     * @param _tokenId specified NFT id to buy
     */
    function buy(
        address _nft,
        uint256 _tokenId
    ) external payable isListedNFT(_nft, _tokenId) {
        ListNFT storage listedNft = listNfts[_nft][_tokenId];

        require(!listedNft.sold, "nft already sold");
        require(msg.value >= listedNft.price, "invalid price");

        listedNft.sold = true;

        uint256 totalPrice = msg.value;
        IKaiKongsNFT nft = IKaiKongsNFT(listedNft.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, msg.value);

            // Transfer royalty fee to collection owner
            payable(royaltyRecipient).transfer(royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(msg.value);
        payable(feeRecipient).transfer(platformFeeTotal);

        // Transfer to nft owner
        payable(listedNft.seller).transfer(totalPrice - platformFeeTotal);

        // Transfer NFT to buyer
        IERC721(listedNft.nft).safeTransferFrom(
            address(this),
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            msg.value,
            listedNft.seller,
            msg.sender
        );
    }

    // @notice Offer listed NFT
    function makeOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _offerPrice
    ) external payable isListedNFT(_nft, _tokenId) {
        require(_offerPrice > 0, "price can not 0");

        ListNFT memory nft = listNfts[_nft][_tokenId];
        require(
            msg.value == _offerPrice,
            "The msg.value is not equal to _offerPrice"
        );

        offerNfts[_nft][_tokenId][msg.sender] = OfferNFT({
            nft: nft.nft,
            tokenId: nft.tokenId,
            offerer: msg.sender,
            offerPrice: _offerPrice,
            date: block.timestamp,
            accepted: false
        });

        emit OfferredNFT(
            nft.nft,
            nft.tokenId,
            _offerPrice,
            block.timestamp,
            msg.sender
        );
    }

    /**
     * @notice cancel the made offer
     * @param _nft NFT collection address to buy
     * @param _tokenId NFT id to buy
     */
    function cancelOffer(
        address _nft,
        uint256 _tokenId
    ) external isOfferredNFT(_nft, _tokenId, msg.sender) {
        OfferNFT memory offer = offerNfts[_nft][_tokenId][msg.sender];
        require(offer.offerer == msg.sender, "not offerer");
        require(!offer.accepted, "offer already accepted");
        delete offerNfts[_nft][_tokenId][msg.sender];
        payable(offer.offerer).transfer(offer.offerPrice);
        emit CanceledOfferredNFT(
            offer.nft,
            offer.tokenId,
            offer.offerPrice,
            msg.sender
        );
    }

    /**
     * @notice listed NFT owner accept offerring
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _offerer the user address that created this offer
     */
    function acceptOfferNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    )
        external
        isOfferredNFT(_nft, _tokenId, _offerer)
        isListedNFT(_nft, _tokenId)
    {
        require(
            listNfts[_nft][_tokenId].seller == msg.sender,
            "not listed owner"
        );
        OfferNFT storage offer = offerNfts[_nft][_tokenId][_offerer];
        ListNFT storage list = listNfts[offer.nft][offer.tokenId];
        require(!list.sold, "already sold");
        require(!offer.accepted, "offer already accepted");

        list.sold = true;
        offer.accepted = true;

        uint256 offerPrice = offer.offerPrice;
        uint256 totalPrice = offerPrice;

        IKaiKongsNFT nft = IKaiKongsNFT(offer.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, offerPrice);

            // Transfer royalty fee to collection owner
            payable(royaltyRecipient).transfer(royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        payable(feeRecipient).transfer(platformFeeTotal);

        // Transfer to seller
        payable(list.seller).transfer(totalPrice - platformFeeTotal);

        // Transfer NFT to offerer
        IERC721(list.nft).safeTransferFrom(
            address(this),
            offer.offerer,
            list.tokenId
        );

        emit AcceptedNFT(
            offer.nft,
            offer.tokenId,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    /**
     * @notice create a auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _price NFT price
     * @param _minBid minimum bid price
     * @param _startTime the time to start bid.
     * @param _endTime the time to end bid and NFT is transfered to max bider.
     */
    function createAuction(
        address _nft,
        uint256 _tokenId,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) external isNotAuction(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        auctionNfts[_nft][_tokenId] = AuctionNFT({
            nft: _nft,
            tokenId: _tokenId,
            creator: msg.sender,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            lastBidder: address(0),
            heighestBid: _price,
            winner: address(0),
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
    }

    /**
     * @notice cancel the auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function cancelAuction(
        address _nft,
        uint256 _tokenId
    ) external isAuction(_nft, _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.lastBidder == address(0), "already have bidder");

        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete auctionNfts[_nft][_tokenId];
    }

    /**
     * @notice Bid place auction
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _bidPrice bid price
     */
    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external payable isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctionNfts[_nft][_tokenId].startTime,
            "auction not start"
        );
        require(
            block.timestamp <= auctionNfts[_nft][_tokenId].endTime,
            "auction ended"
        );
        require(
            _bidPrice == msg.value,
            "The msg.value is not equal to _bidPrice"
        );
        require(
            _bidPrice >=
                auctionNfts[_nft][_tokenId].heighestBid +
                    auctionNfts[_nft][_tokenId].minBid,
            "less than min bid price"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.heighestBid;

            // Transfer back to last bidder
            payable(lastBidder).transfer(lastBidPrice);
        }

        // Set new heighest bid price
        auction.lastBidder = msg.sender;
        auction.heighestBid = _bidPrice;

        emit PlacedBid(_nft, _tokenId, _bidPrice, msg.sender);
    }

    /**
     * @notice complete auction, can call by auction creator, heighest bidder, or marketplace owner only!
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function completeBid(address _nft, uint256 _tokenId) external {
        require(!auctionNfts[_nft][_tokenId].success, "already resulted");
        require(
            msg.sender == owner() ||
                msg.sender == auctionNfts[_nft][_tokenId].creator ||
                msg.sender == auctionNfts[_nft][_tokenId].lastBidder,
            "not creator, winner, or owner"
        );
        require(
            block.timestamp > auctionNfts[_nft][_tokenId].endTime,
            "auction not ended"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        IKaiKongsNFT KaiKongsNft = IKaiKongsNFT(_nft);
        address royaltyRecipient = KaiKongsNft.getRoyaltyRecipient();
        uint256 royaltyFee = KaiKongsNft.getRoyaltyFee();

        uint256 heighestBid = auction.heighestBid;
        uint256 totalPrice = heighestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, heighestBid);

            // Transfer royalty fee to collection owner
            payable(royaltyRecipient).transfer(royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platfrom fee
        uint256 platformFeeTotal = calculatePlatformFee(heighestBid);
        payable(feeRecipient).transfer(platformFeeTotal);

        // Transfer to auction creator
        payable(auction.creator).transfer(totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.heighestBid,
            msg.sender
        );
    }

    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 100000;
    }

    function calculateRoyalty(
        uint256 _royalty,
        uint256 _price
    ) public pure returns (uint256) {
        return (_price * _royalty) / 100000;
    }

    function getListedNFT(
        address _nft,
        uint256 _tokenId
    ) public view returns (ListNFT memory) {
        return listNfts[_nft][_tokenId];
    }

    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "can't be 0 address");
        feeRecipient = _feeRecipient;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
