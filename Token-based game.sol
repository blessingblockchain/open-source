/ SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TokenGame {
    address public owner;
    ERC20 public token;

    enum GameState { Open, Closed }

    struct Game {
        uint256 gameId;
        address player;
        uint256 betAmount;
        bool isWin;
    }

    mapping(uint256 => Game) public games;
    uint256 public totalGames;
    GameState public state;

    event GameCreated(uint256 indexed gameId, address indexed player, uint256 betAmount);
    event GameResult(uint256 indexed gameId, bool indexed isWin, uint256 rewardAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    modifier onlyOpenState() {
        require(state == GameState.Open, "The game is closed.");
        _;
    }

    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = ERC20(_tokenAddress);
        state = GameState.Open;
    }

    function createGame(uint256 _betAmount) external onlyOpenState {
        require(_betAmount > 0, "Bet amount should be greater than zero.");

        // Transfer the tokens from the player to the contract
        token.transferFrom(msg.sender, address(this), _betAmount);

        totalGames++;
        games[totalGames] = Game(totalGames, msg.sender, _betAmount, false);

        emit GameCreated(totalGames, msg.sender, _betAmount);
    }

    function closeGame(uint256 _gameId, bool _isWin, uint256 _rewardAmount) external onlyOpenState onlyOwner {
        require(_gameId <= totalGames, "Invalid game ID.");
        require(_rewardAmount > 0, "Reward amount should be greater than zero.");

        Game storage game = games[_gameId];
        require(game.player != address(0), "Game does not exist.");

        game.isWin = _isWin;

        if (_isWin) {
            // Transfer the reward tokens from the contract to the player
            token.transfer(game.player, _rewardAmount);
        }

        emit GameResult(_gameId, _isWin, _rewardAmount);
    }

    function setGameState(GameState _state) external onlyOwner {
        state = _state;
    }
}

contract ERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "Invalid recipient address.");
        require(_value > 0, "Transfer amount must be greater than zero.");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance.");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), "Invalid spender address.");

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_from != address(0), "Invalid sender address.");
        require(_to != address(0), "Invalid recipient address.");
        require(_value > 0, "Transfer amount must be greater than zero.");
        require(balanceOf[_from] >= _value, "Insufficient balance.");
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance.");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
}