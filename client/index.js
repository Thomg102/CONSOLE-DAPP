const Web3 = require("web3");
require('dotenv').config()
const IERC20Json = require("./contracts/IERC20.json");
const IERC721Json = require("./contracts/IERC721.json");
const Trade = require("./contracts/Trade.json");
const Trade721 = "0x113F2C0C8d11674D0A50693ccb58C9211523AC87";
const privateKey = process.env.PRIVATE_KEY;
const TradeAddress = process.env.TRADE_ADDRESS;
console.log(privateKey)
let tradeContract;
let signer;
let web3;
const start = async() => {
    web3 = new Web3(new Web3.providers.WebsocketProvider(process.env.WSS_RINKEBY));
    signer = web3.eth.accounts.wallet.add(privateKey);
    tradeContract = await new web3.eth.Contract(Trade.abi, TradeAddress);
    // console.log(tradeContract.options.address)
    // await askETHToToken20(2, "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", 1);
    // await bidETHToToken20(0, '1000000000000000000');
    await tradeContract.methods.asks(0).call().then(data => {
        console.log(data);
    })

    // await filter("0", "", "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984")
    console.log("hello")
}
start()

function IERC20(tokenAddress) {
    return new web3.eth.Contract(IERC20Json.abi, tokenAddress);
}
// IERC20("0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984").methods.allowance("0xaFc15374b980F7aeb7f63123E94aee915d11F81D", "0xa68a621367346Bedb9A0325087856598903C9C70").call().then(data => { console.log(data) })

const askToken20ToToken20 = async(tokenAAddress, tokenBAddress, amountA, priceofPair) => {
    await IERC20(tokenAAddress).methods.approve(tradeContract.options.address, amountA).send({
        from: signer.address,
        gas: 5500000
    })
    await tradeContract.methods.askToken20ToToken20(tokenAAddress, tokenBAddress, amountA, priceofPair).send({
            from: signer.address,
            gas: 5500000
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);

}

const askETHToToken20 = async(amountETH, tokenBAddress, priceofPair) => {
    await tradeContract.methods.askETHToToken20(tokenBAddress, priceofPair).send({
            from: signer.address,
            gas: 5500000,
            value: web3.utils.toWei(amountETH.toString(), "ether")
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);

}

const askToken20ToETH = async(tokenAAddress, amountA, priceofPair) => {
    await IERC20(tokenAAddress).methods.approve(tradeContract.options.address, amountA).send({
        from: signer.address,
        gas: 5500000
    })
    await tradeContract.methods.askToken20ToToken20(tokenAAddress, tokenBAddress, amountA, priceofPair).send({
            from: signer.address,
            gas: 5500000
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);

}

const getBestPrice = async(tokenAAddress, tokenBAddress) => {
    return await tradeContract.methods.getBestPrice(tokenAAddress, tokenBAddress).call();
}

const bidToken20ToToken20 = async(askId, amountTokenDesired) => {
    let tokenB;
    await tradeContract.methods.asks(askId).call().then(data => {
        tokenB = data.tokenB;
    })
    await IERC20(tokenB).methods.approve(tradeContract.options.address, amountTokenDesired).send({
        from: signer.address,
        gas: 5500000
    })
    await tradeContract.methods.bidToken20ToToken20(askId, amountTokenDesired).send({
            from: signer.address,
            gas: 5500000
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);
}

const bidETHToToken20 = async(askId, amountTokenDesired) => {
    let tokenBAddress;
    await tradeContract.methods.asks(askId).call().then(data => {
        tokenBAddress = data.tokenB;
    })
    console.log(tokenBAddress);
    await IERC20(tokenBAddress).methods.approve(tradeContract.options.address, amountTokenDesired).send({
        from: signer.address,
        gas: 5500000
    })
    await tradeContract.methods.bidETHToToken20(askId, amountTokenDesired).send({
            from: signer.address,
            gas: 5500000
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);
}

const bidToken20ToETH = async(askId, amountETH) => {
    await tradeContract.methods.bidToken20ToETH(askId).send({
            from: signer.address,
            gas: 5500000,
            value: web3.utils.toWei(amountETH.toString, 'ether')
        }).on("transactionHash", hash => {
            console.log("Transaction hash: " + hash);
        })
        .on("receipt", receipt => {
            console.log("receipt: " + receipt);
        })
        .on("error", console.error);
}

const createPrivateKey = async() => {
    return await web3.eth.accounts.create();
}
const createWallet = async(privateKey) => {
    return await web3.eth.accounts.wallet.add(privateKey);
}
const createAccountFromPrivateKey = async(amountAccount) => {
        return await web3.eth.accounts.wallet.create(amountAccount);
    }
    // createAccountFromPrivateKey(2).then(data => {
    //     console.log(data)
    // })

const filter = async(id, tokenA, tokenB) => {
    await tradeContract.getPastEvents("NewAsk", {
            filter: { _id: id, _tokenA: tokenA, _tokenB: tokenB },
            fromBlock: 0,
            toBlock: 'latest'
        })
        .then(events => {
            events.forEach(element => {
                console.log(element.returnValues)
            });
        })
}