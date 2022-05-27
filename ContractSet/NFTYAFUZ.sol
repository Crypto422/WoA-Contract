// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract boardsYafuz is ERC721, Ownable {
  address public tokenYaz;
  address public USER;

  ERC20 myTokenContract;
  mapping(address => uint256) public balances;
  uint256 public totalLigas = 15;

  constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol)
  {
    tokenYaz = 0x0198f23dA491c9Fc44E890D00e43599368dA2696;
    USER = 0x4c18A9a0D1474f0Ead1175E05cC548cef6F67bD1;
    myTokenContract = ERC20(tokenYaz);
    myTokenContract.approve(
      address(this),
      999999999999999999999999999999999999999999999999999999999999999999
    );
  }

  uint256 COUNTER;
  uint256 fee = 0.001 ether;
  struct board {
    string userID;
    uint256 uid;
    uint256 ADN;
    uint8 ciclaje;
    uint8 rerity;
  }
  //creat una estructura de almacenamiento
  //donde se almacenara los tableron de juegos
  board[] public Boards;
  event evNewBoard(
    address indexed owner,
    uint256 uid,
    uint256 ADN,
    string userID,
    uint8 ciclaje,
    uint8 rerity
  );

  function updateTotalLiga(uint256 _numLigas) public {
    totalLigas = _numLigas;
  }

  // ============================================================================
  // Function
  // function de generar codigos aleatorios
  function _createRandomNum(uint256 _mod) internal view returns (uint256) {
    uint256 randoNum = uint256(
      keccak256(abi.encodePacked(block.timestamp, msg.sender))
    );
    return randoNum % _mod;
  }

  // ============================================================================
  // Actualizacion de los precios de los token NFT
  //
  function updateFee(uint256 _fee) external onlyOwner {
    fee = _fee;
  }

  // extraccion de los ether del smart contract hacia el owner
  function withdraw() external payable onlyOwner {
    address payable _owner = payable(owner());
    _owner.transfer(address(this).balance);
  }

  // Creacion de los (Lib/labios) NFT
  function _createBoard(
    string memory userID,
    uint8 rarity,
    address _address
  ) internal {
    uint8 randRarity = rarity;
    uint256 randADN = _createRandomNum(10**16);
    board memory newBoard = board(userID, COUNTER, randADN, 1, randRarity);
    Boards.push(newBoard);
    _safeMint(_address, COUNTER);
    emit evNewBoard(_address, COUNTER, randADN, userID, 1, randRarity);
    COUNTER++;
  }

  // ============================================================================
  // Actualizacion de los precios de los token NFT
  //
  function createRandomBoard(
    string memory userID,
    uint8 rarity,
    address _address
  ) public payable UnicamenteOwner(rarity, _address) {
    _createBoard(userID, rarity, _address);
  }

  //obtener de todos los boards
  function getBoards() public view returns (board[] memory) {
    return Boards;
  }

  // Visualizar el Balance del smart contract
  function moneySmartContract() public view returns (uint256) {
    return myTokenContract.balanceOf(address(USER));
  }

  //Ver saldo de los usuarios

  function _balanceOf(address _address) public view returns (uint256) {
    return myTokenContract.balanceOf(_address);
  }

  function addressSmartContract() public view returns (address) {
    return address(this);
  }

  function mintNFTOwner(
    uint8 _rarity,
    string memory userID,
    uint256 amount
  ) public validateOneNft(_rarity, amount) {
    myTokenContract.transferFrom(address(this), address(USER), amount);
    _createBoard(userID, _rarity, msg.sender);
  }

  // Obtener los toliken NFT de un usuatio()
  function getOwnerBoard(address _owner) public view returns (board[] memory) {
    board[] memory result = new board[](balanceOf(_owner));
    uint256 Counter = 0;
    for (uint256 i = 0; i < Boards.length; i++) {
      if (ownerOf(i) == _owner) {
        result[Counter] = Boards[i];
        Counter++;
      }
    }
    return result;
  }

  //List one board
  function getBoardByID(uint256 uid) public view returns (board memory) {
    uint8 i = 0;
    while (i < Boards.length) {
      if (Boards[i].uid == uid) {
        break;
      }
      i++;
    }
    board memory y = Boards[i];
    return y;
  } // invcrementar de nivel un nft

  function ciclajeUP(uint256 _uidBoard) public {
    require(ownerOf(_uidBoard) == msg.sender);
    board storage _board = Boards[_uidBoard];
    _board.ciclaje++;
  }

  function fetchPage(uint256 cursor, uint256 howMany)
    public
    view
    returns (
      board[] memory values,
      uint256 newCursor,
      uint256 total
    )
  {
    uint256 length = howMany;
    if (length > Boards.length - cursor) {
      length = Boards.length - cursor;
    }

    values = new board[](length);
    for (uint256 i = 0; i < length; i++) {
      values[i] = Boards[cursor + i];
    }

    return (values, cursor + length, Boards.length);
  }

  modifier UnicamenteOwner(uint8 _rarity, address _owner) {
    require(_rarity <= totalLigas, "Esta liga no existe");
    bool valR = true;
    // Requiere que la direccion introducido por parametro sea igual al owner del contrato
    require(msg.sender == owner(), "just run admin");
    uint8 i = 0;
    while (i < Boards.length) {
      board memory newBoard = Boards[i];

      if (ownerOf(i) == _owner && newBoard.rerity == _rarity) {
        valR = false;
        break;
      }
      i++;
    }

    require(valR, "you already have an NFT of this rank, buy the next level");
    _;
  }
  modifier validateOneNft(uint8 _rarity, uint256 amount) {
    require(msg.sender != address(0), "Zero address");
    require(_rarity <= totalLigas, "Esta liga no existe");
    uint256 totalSaldo = getBalanceUser(address(this));
    require(
      totalSaldo >= amount,
      "you don't have enough coins to make this transaction"
    );
    bool valR = true;
    uint8 i = 0;
    while (i < Boards.length) {
      board memory newBoard = Boards[i];

      if (ownerOf(i) == msg.sender && newBoard.rerity == _rarity) {
        valR = false;
        break;
      }
      i++;
    }

    require(valR, "you already have an NFT of this rank, buy the next level");
    _;
  }

  function getBalanceUser(address _user) public view returns (uint256) {
    return myTokenContract.balanceOf(address(_user));
  }

  function decimals() public view returns (uint256) {
    return myTokenContract.decimals();
  }

  function UpdateAddressCYAZ(address _address) public {
    tokenYaz = _address;
  }

  function updateUSERPay(address _address) public {
    USER = _address;
  }
}
