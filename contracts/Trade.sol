// SPDX-License-Identifier: MIT
pragma solidity >=0.5.1;

abstract contract IERC20 {
    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool);

    function transfer(address to, uint256 value)
        external
        virtual
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external virtual returns (bool);

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256);
}

contract Trade {
    struct Ask {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 price;
    }

    Ask[] public asks;

    mapping(uint256 => address) public askToOwner;
    mapping(address => uint256) public ownerAskCount;
    // mapping(address => mapping(address => uint256[])) public bestPrice;

    event NewAsk(
        uint256 indexed _id,
        address indexed _tokenA,
        address indexed _tokenB,
        uint256 _amountA,
        uint256 _priceOfPair
    );
    event Bid(
        uint256 indexed _id,
        address indexed _tokenA,
        address indexed _tokenB,
        uint256 _amountA,
        uint256 _amountB
    );

    // Ask:  A user (asker) create a request to trade one asset to another,
    // sending the amount of asset they one to trade into the contract.
    // Input: types of asset one to trade, amount of the asset one to trade, price of the asset pair tokenA = x tokenB
    function askToken20ToToken20(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _priceOfPair
    ) external returns (uint256) {
        asks.push(Ask(_tokenA, _tokenB, _amountA, _priceOfPair));
        uint256 id = asks.length - 1;
        require(
            IERC20(_tokenA).allowance(msg.sender, address(this)) >= _amountA,
            "error: this contract chua duoc approve token"
        );
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        askToOwner[id] = msg.sender;
        ownerAskCount[msg.sender]++;

        emit NewAsk(id, _tokenA, _tokenB, _amountA, _priceOfPair);
        return id;
    }

    function askETHToToken20(address _tokenB, uint256 _priceOfPair)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0, "Error: sender chua gui ether");
        asks.push(Ask(address(0), _tokenB, msg.value, _priceOfPair));
        uint256 id = asks.length - 1;

        askToOwner[id] = msg.sender;
        ownerAskCount[msg.sender]++;

        emit NewAsk(id, address(0), _tokenB, msg.value, _priceOfPair);
        return id;
    }

    function askToken20ToETH(
        address _tokenA,
        uint256 _amountA,
        uint256 _priceOfPair
    ) external returns (uint256) {
        asks.push(Ask(_tokenA, address(0), _amountA, _priceOfPair));
        uint256 id = asks.length - 1;
        require(
            IERC20(_tokenA).allowance(msg.sender, address(this)) >= _amountA,
            "error: this contract chua duoc approve token"
        );
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        askToOwner[id] = msg.sender;
        ownerAskCount[msg.sender]++;

        emit NewAsk(id, _tokenA, address(0), _amountA, _priceOfPair);
        return id;
    }

    // BestPrice: Get the best price of an asset pair
    function getBestPrice(address _tokenA, address _tokenB)
        public
        view
        returns (uint256)
    {
        uint256 max = 0;
        uint256 length = asks.length;
        for (uint256 i = 0; i < length; i++) {
            if (asks[i].tokenA == _tokenA && asks[i].tokenB == _tokenB) {
                if (asks[i].price > max) max = asks[i].price;
            }
        }
        return max;
    }

    // Bid: A user (bidder) create a request
    // to accept the ask request of other user and execute the trade.
    // Input: Ask request id, amount of asset the bidder want to trade.
    function bidToken20ToToken20(uint256 _askId, uint256 _amountDesired)
        external
        returns (bool)
    {
        Ask storage askRequest = asks[_askId];
        require(askRequest.amountA != 0, "error: yeu cau nay da duoc giao dich xong");
        uint256 amountBToTrade = askRequest.amountA * askRequest.price;
        uint256 amountAToTrade = _amountDesired / askRequest.price;
        require(amountBToTrade >= _amountDesired, "error: so luong bidder muon trao doi phai nho hoac bang so luong asker yeu cau");

        address recipient = askToOwner[_askId];
        require(
            IERC20(askRequest.tokenB).allowance(msg.sender, address(this)) >=
                _amountDesired,
            "error: this contract chua duoc approve token"
        );
        IERC20(askRequest.tokenB).transferFrom(
            msg.sender,
            recipient,
            _amountDesired
        );
        IERC20(askRequest.tokenA).transfer(msg.sender, amountAToTrade);

        askRequest.amountA = askRequest.amountA - amountAToTrade;

        emit Bid(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            amountAToTrade,
            _amountDesired
        );
        return true;
    }

    function bidETHToToken20(uint256 _askId, uint256 _amountDesired)
        external
        returns (bool)
    {
        Ask storage askRequest = asks[_askId];
        require(askRequest.amountA != 0,"error: yeu cau nay da duoc giao dich xong");
        uint256 amountBToTrade = askRequest.amountA * askRequest.price;
        uint256 amountAToTrade = _amountDesired / askRequest.price;
        require(amountBToTrade >= _amountDesired, "error: so luong bidder muon trao doi phai nho hoac bang so luong asker yeu cau");
        address recipient = askToOwner[_askId];
        require(
            IERC20(askRequest.tokenB).allowance(msg.sender, address(this)) >=
                _amountDesired,
            "error: this contract chua duoc approve token"
        );
        IERC20(askRequest.tokenB).transferFrom(
            msg.sender,
            recipient,
            _amountDesired
        );
        address payable bidder = payable(msg.sender);
        bidder.transfer(amountAToTrade);

        askRequest.amountA = askRequest.amountA - amountAToTrade;

        emit Bid(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            amountAToTrade,
            _amountDesired
        );
        return true;
    }

    function bidToken20ToETH(uint256 _askId) external payable returns (bool) {
        require(msg.value > 0, "error: bidder chua gui kem ether");
        Ask storage askRequest = asks[_askId];
        require(askRequest.amountA != 0, "error: yeu cau nay da duoc giao dich xong");
        uint256 amountBToTrade = askRequest.amountA * askRequest.price;
        uint256 amountAToTrade = msg.value / askRequest.price;
        require(amountBToTrade >= msg.value,"error: so luong bidder muon trao doi phai nho hoac bang so luong asker yeu cau");
        address payable recipient = payable(askToOwner[_askId]);

        recipient.transfer(msg.value);
        IERC20(askRequest.tokenA).transfer(msg.sender, amountAToTrade);

        askRequest.amountA = askRequest.amountA - amountAToTrade;

        emit Bid(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            amountAToTrade,
            msg.value
        );
        return true;
    }
}
