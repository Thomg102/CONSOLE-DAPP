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

abstract contract IERC721 {
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function approve(address to, uint256 tokenId) public virtual;

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address operator);
}

contract TradeTo721 {
    struct Ask721 {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    Ask721[] public ask721s;

    mapping(uint256 => address) public askToOwner721;
    mapping(address => uint256) public ownerAskCount721;

    event NewAsk721(
        uint256 indexed _id,
        address indexed _tokenA,
        address indexed _tokenB,
        uint256 _amountA,
        uint256 _amountB
    );
    event Bid721(
        uint256 indexed _id,
        address indexed _tokenA,
        address indexed _tokenB,
        uint256 _amountA,
        uint256 _amountB
    );

    function askETHToToken721(address _tokenB, uint256 _tokenId)
        external
        payable
        returns (uint256)
    {
        require(msg.value > 0);
        ask721s.push(Ask721(address(0), _tokenB, msg.value, _tokenId));
        uint256 id = ask721s.length - 1;

        askToOwner721[id] = msg.sender;
        ownerAskCount721[msg.sender]++;

        emit NewAsk721(id, address(0), _tokenB, msg.value, _tokenId);
        return id;
    }

    function askToken20ToToken721(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _tokenId
    ) external returns (uint256) {
        ask721s.push(Ask721(_tokenA, _tokenB, _amountA, _tokenId));
        uint256 id = ask721s.length - 1;
        require(
            IERC20(_tokenA).allowance(msg.sender, address(this)) >= _amountA,
            "error: this contract chua duoc approve token"
        );
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        askToOwner721[id] = msg.sender;
        ownerAskCount721[msg.sender]++;

        emit NewAsk721(id, _tokenA, _tokenB, _amountA, _tokenId);
        return id;
    }

    function askToken721ToETH(
        address _tokenA,
        uint256 _tokenId,
        uint256 _amountB
    ) external returns (uint256) {
        require(
            IERC721(_tokenA).ownerOf(_tokenId) == msg.sender &&
                IERC721(_tokenA).getApproved(_tokenId) == address(this)
        );
        ask721s.push(Ask721(_tokenA, address(0), _tokenId, _amountB));
        uint256 id = ask721s.length - 1;

        IERC721(_tokenA).transferFrom(msg.sender, address(this), _tokenId);

        askToOwner721[id] = msg.sender;
        ownerAskCount721[msg.sender]++;

        emit NewAsk721(id, _tokenA, address(0), _tokenId, _amountB);
        return id;
    }

    // Bid: A user (bidder) create a request
    // to accept the ask request of other user and execute the trade.
    // Input: Ask request id, amount of asset the bidder want to trade.

    function bidETHToToken721(uint256 _askId, uint256 _tokenId)
        external
        returns (bool)
    {
        Ask721 storage askRequest = ask721s[_askId];
        require(
            IERC721(askRequest.tokenB).ownerOf(_tokenId) == msg.sender &&
                IERC721(askRequest.tokenB).getApproved(_tokenId) ==
                address(this)
        );
        require(askRequest.amountA > 0);
        require(askRequest.amountB == _tokenId);
        address recipient = askToOwner721[_askId];

        IERC721(askRequest.tokenB).transferFrom(
            msg.sender,
            recipient,
            _tokenId
        );
        address payable bidder = payable(msg.sender);
        bidder.transfer(askRequest.amountA);

        askRequest.amountA = 0;

        emit Bid721(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            askRequest.amountA, //eth
            _tokenId
        );
        return true;
    }

    function bidToken20ToToken721(uint256 _askId, uint256 _tokenId)
        external
        returns (bool)
    {
        Ask721 storage askRequest = ask721s[_askId];
        require(
            IERC721(askRequest.tokenB).ownerOf(_tokenId) == msg.sender &&
                IERC721(askRequest.tokenB).getApproved(_tokenId) ==
                address(this)
        );
        require(askRequest.amountA > 0);
        require(askRequest.amountB == _tokenId);
        address recipient = askToOwner721[_askId];

        IERC721(askRequest.tokenB).transferFrom(
            msg.sender,
            recipient,
            _tokenId
        );

        IERC20(askRequest.tokenA).transfer(msg.sender, askRequest.amountA);

        askRequest.amountA = 0;

        emit Bid721(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            askRequest.amountA, //eth
            _tokenId
        );
        return true;
    }

    function bidToken721ToETH(uint256 _askId) external payable returns (bool) {
        require(msg.value > 0);
        Ask721 storage askRequest = ask721s[_askId];

        require(askRequest.amountB > 0);

        address payable recipient = payable(askToOwner721[_askId]);

        recipient.transfer(msg.value);
        IERC721(askRequest.tokenA).transferFrom(
            address(this),
            msg.sender,
            askRequest.amountA //tokenID
        );

        askRequest.amountB = 0;

        emit Bid721(
            _askId,
            askRequest.tokenA,
            askRequest.tokenB,
            askRequest.amountA, //tokenId
            msg.value
        );
        return true;
    }
}
