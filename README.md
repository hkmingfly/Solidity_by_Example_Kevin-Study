# Solidity_by_Example_Kevin-Study
1. Voting
The following contract is quite complex, but showcases a lot of Solidity’s features. It implements a voting contract. Of course, the main problems of electronic voting is how to assign voting rights to the correct persons and how to prevent manipulation. We will not solve all problems here, but at least we will show how delegated voting can be done so that vote counting is automatic and completely transparent at the same time.
The idea is to create one contract per ballot, providing a short name for each option. Then the creator of the contract who serves as chairperson will give the right to vote to each address individually.
The persons behind the addresses can then choose to either vote themselves or to delegate their vote to a person they trust.
At the end of the voting time, winningProposal() will return the proposal with the largest number of votes.

2. Blind Auction
In this section, we will show how easy it is to create a completely blind auction contract on Ethereum. We will start with an open auction where everyone can see the bids that are made and then extend this contract into a blind auction where it is not possible to see the actual bid until the bidding period ends.
2.1. Simple Open Auction
The general idea of the following simple auction contract is that everyone can send their bids during a bidding period. The bids already include sending money / Ether in order to bind the bidders to their bid. If the highest bid is raised, the previous highest bidder gets their money back. After the end of the bidding period, the contract has to be called manually for the beneficiary to receive their money - contracts cannot activate themselves.
2.2. Blind Auction
The previous open auction is extended to a blind auction in the following. The advantage of a blind auction is that there is no time pressure towards the end of the bidding period. Creating a blind auction on a transparent computing platform might sound like a contradiction, but cryptography comes to the rescue.
During the bidding period, a bidder does not actually send their bid, but only a hashed version of it. Since it is currently considered practically impossible to find two (sufficiently long) values whose hash values are equal, the bidder commits to the bid by that. After the end of the bidding period, the bidders have to reveal their bids: They send their values unencrypted and the contract checks that the hash value is the same as the one provided during the bidding period.
Another challenge is how to make the auction binding and blind at the same time: The only way to prevent the bidder from just not sending the money after they won the auction is to make them send it together with the bid. Since value transfers cannot be blinded in Ethereum, anyone can see the value.
The following contract solves this problem by accepting any value that is larger than the highest bid. Since this can of course only be checked during the reveal phase, some bids might be invalid, and this is on purpose (it even provides an explicit flag to place invalid bids with high value transfers): Bidders can confuse competition by placing several high or low invalid bids.

3. Safe Remote Purchase
Purchasing goods remotely currently requires multiple parties that need to trust each other. The simplest configuration involves a seller and a buyer. The buyer would like to receive an item from the seller and the seller would like to get money (or an equivalent) in return. The problematic part is the shipment here: There is no way to determine for sure that the item arrived at the buyer.
There are multiple ways to solve this problem, but all fall short in one or the other way. In the following example, both parties have to put twice the value of the item into the contract as escrow. As soon as this happened, the money will stay locked inside the contract until the buyer confirms that they received the item. After that, the buyer is returned the value (half of their deposit) and the seller gets three times the value (their deposit plus the value). The idea behind this is that both parties have an incentive to resolve the situation or otherwise their money is locked forever.
This contract of course does not solve the problem, but gives an overview of how you can use state machine-like constructs inside a contract.

4. Creating and verifying signatures
Imagine Alice wants to send some Ether to Bob, i.e. Alice is the sender and Bob is the recipient.
Alice only needs to send cryptographically signed messages off-chain (e.g. via email) to Bob and it is similar to writing checks.
Alice and Bob use signatures to authorise transactions, which is possible with smart contracts on Ethereum. Alice will build a simple smart contract that lets her transmit Ether, but instead of calling a function herself to initiate a payment, she will let Bob do that, and therefore pay the transaction fee.
The contract will work as follows:
Alice deploys the ReceiverPays contract, attaching enough Ether to cover the payments that will be made.
Alice authorises a payment by signing a message with her private key.
Alice sends the cryptographically signed message to Bob. The message does not need to be kept secret (explained later), and the mechanism for sending it does not matter.
Bob claims his payment by presenting the signed message to the smart contract, it verifies the authenticity of the message and then releases the funds.
Creating the signature
Alice does not need to interact with the Ethereum network to sign the transaction, the process is completely offline. In this tutorial, we will sign messages in the browser using web3.js and MetaMask, using the method described in EIP-712, as it provides a number of other security benefits.

/// Hashing first makes things easier
var hash = web3.utils.sha3("message to sign");
web3.eth.personal.sign(hash, web3.eth.defaultAccount, function () { console.log("Signed"); });
Note
The web3.eth.personal.sign prepends the length of the message to the signed data. Since we hash first, the message will always be exactly 32 bytes long, and thus this length prefix is always the same.
What to Sign
For a contract that fulfils payments, the signed message must include:
The recipient’s address.
The amount to be transferred.
Protection against replay attacks.
A replay attack is when a signed message is reused to claim authorization for a second action. To avoid replay attacks we use the same technique as in Ethereum transactions themselves, a so-called nonce, which is the number of transactions sent by an account. The smart contract checks if a nonce is used multiple times.
Another type of replay attack can occur when the owner deploys a ReceiverPays smart contract, makes some payments, and then destroys the contract. Later, they decide to deploy the RecipientPays smart contract again, but the new contract does not know the nonces used in the previous deployment, so the attacker can use the old messages again.
Alice can protect against this attack by including the contract’s address in the message, and only messages containing the contract’s address itself will be accepted. You can find an example of this in the first two lines of the claimPayment() function of the full contract at the end of this section.
Packing arguments
Now that we have identified what information to include in the signed message, we are ready to put the message together, hash it, and sign it. For simplicity, we concatenate the data. The ethereumjs-abi library provides a function called soliditySHA3 that mimics the behaviour of Solidity’s keccak256 function applied to arguments encoded using abi.encodePacked. Here is a JavaScript function that creates the proper signature for the ReceiverPays example:
// recipient is the address that should be paid.
// amount, in wei, specifies how much ether should be sent.
// nonce can be any unique number to prevent replay attacks
// contractAddress is used to prevent cross-contract replay attacks
function signPayment(recipient, amount, nonce, contractAddress, callback) {
    var hash = "0x" + abi.soliditySHA3(
        ["address", "uint256", "uint256", "address"],
        [recipient, amount, nonce, contractAddress]
    ).toString("hex");

    web3.eth.personal.sign(hash, web3.eth.defaultAccount, callback);
}
Recovering the Message Signer in Solidity
In general, ECDSA signatures consist of two parameters, r and s. Signatures in Ethereum include a third parameter called v, that you can use to verify which account’s private key was used to sign the message, and the transaction’s sender. Solidity provides a built-in function ecrecover that accepts a message along with the r, s and v parameters and returns the address that was used to sign the message.
Extracting the Signature Parameters
Signatures produced by web3.js are the concatenation of r, s and v, so the first step is to split these parameters apart. You can do this on the client-side, but doing it inside the smart contract means you only need to send one signature parameter rather than three. Splitting apart a byte array into its constituent parts is a mess, so we use inline assembly to do the job in the splitSignature function (the third function in the full contract at the end of this section).
Computing the Message Hash
The smart contract needs to know exactly what parameters were signed, and so it must recreate the message from the parameters and use that for signature verification. The functions prefixed and recoverSigner do this in the claimPayment function.
5. A Simple Payment Channel
What is a Payment Channel?
Payment channels allow participants to make repeated transfers of Ether without using transactions. This means that you can avoid the delays and fees associated with transactions. We are going to explore a simple unidirectional payment channel between two parties (Alice and Bob). It involves three steps:
Alice funds a smart contract with Ether. This “opens” the payment channel.
Alice signs messages that specify how much of that Ether is owed to the recipient. This step is repeated for each payment.
Bob “closes” the payment channel, withdrawing his portion of the Ether and sending the remainder back to the sender.
Note
Only steps 1 and 3 require Ethereum transactions, step 2 means that the sender transmits a cryptographically signed message to the recipient via off chain methods (e.g. email). This means only two transactions are required to support any number of transfers.
Bob is guaranteed to receive his funds because the smart contract escrows the Ether and honours a valid signed message. The smart contract also enforces a timeout, so Alice is guaranteed to eventually recover her funds even if the recipient refuses to close the channel. It is up to the participants in a payment channel to decide how long to keep it open. For a short-lived transaction, such as paying an internet café for each minute of network access, the payment channel may be kept open for a limited duration. On the other hand, for a recurring payment, such as paying an employee an hourly wage, the payment channel may be kept open for several months or years.
Opening the Payment Channel
To open the payment channel, Alice deploys the smart contract, attaching the Ether to be escrowed and specifying the intended recipient and a maximum duration for the channel to exist. This is the function SimplePaymentChannel in the contract, at the end of this section.
Making Payments
Alice makes payments by sending signed messages to Bob. This step is performed entirely outside of the Ethereum network. Messages are cryptographically signed by the sender and then transmitted directly to the recipient.
Each message includes the following information:
The smart contract’s address, used to prevent cross-contract replay attacks.
The total amount of Ether that is owed the recipient so far.
A payment channel is closed just once, at the end of a series of transfers. Because of this, only one of the messages sent is redeemed. This is why each message specifies a cumulative total amount of Ether owed, rather than the amount of the individual micropayment. The recipient will naturally choose to redeem the most recent message because that is the one with the highest total. The nonce per-message is not needed anymore, because the smart contract only honours a single message. The address of the smart contract is still used to prevent a message intended for one payment channel from being used for a different channel.
Here is the modified JavaScript code to cryptographically sign a message from the previous section:
function constructPaymentMessage(contractAddress, amount) {
    return abi.soliditySHA3(
        ["address", "uint256"],
        [contractAddress, amount]
    );
}
function signMessage(message, callback) {
    web3.eth.personal.sign(
        "0x" + message.toString("hex"),
        web3.eth.defaultAccount,
        callback
    );
}
// contractAddress is used to prevent cross-contract replay attacks.
// amount, in wei, specifies how much Ether should be sent.
function signPayment(contractAddress, amount, callback) {
    var message = constructPaymentMessage(contractAddress, amount);
    signMessage(message, callback);
}
Closing the Payment Channel
When Bob is ready to receive his funds, it is time to close the payment channel by calling a close function on the smart contract. Closing the channel pays the recipient the Ether they are owed and destroys the contract, sending any remaining Ether back to Alice. To close the channel, Bob needs to provide a message signed by Alice.
The smart contract must verify that the message contains a valid signature from the sender. The process for doing this verification is the same as the process the recipient uses. The Solidity functions isValidSignature and recoverSigner work just like their JavaScript counterparts in the previous section, with the latter function borrowed from the ReceiverPays contract.
Only the payment channel recipient can call the close function, who naturally passes the most recent payment message because that message carries the highest total owed. If the sender were allowed to call this function, they could provide a message with a lower amount and cheat the recipient out of what they are owed.
The function verifies the signed message matches the given parameters. If everything checks out, the recipient is sent their portion of the Ether, and the sender is sent the rest via a selfdestruct. You can see the close function in the full contract.
Channel Expiration
Bob can close the payment channel at any time, but if they fail to do so, Alice needs a way to recover her escrowed funds. An expiration time was set at the time of contract deployment. Once that time is reached, Alice can call claimTimeout to recover her funds. You can see the claimTimeout function in the full contract.
After this function is called, Bob can no longer receive any Ether, so it is important that Bob closes the channel before the expiration is reached.
Note
The function splitSignature does not use all security checks. A real implementation should use a more rigorously tested library, such as openzepplin’s version of this code.
Verifying Payments
Unlike in the previous section, messages in a payment channel aren’t redeemed right away. The recipient keeps track of the latest message and redeems it when it’s time to close the payment channel. This means it’s critical that the recipient perform their own verification of each message. Otherwise there is no guarantee that the recipient will be able to get paid in the end.
The recipient should verify each message using the following process:
Verify that the contract address in the message matches the payment channel.
Verify that the new total is the expected amount.
Verify that the new total does not exceed the amount of Ether escrowed.
Verify that the signature is valid and comes from the payment channel sender.
We’ll use the ethereumjs-util library to write this verification. The final step can be done a number of ways, and we use JavaScript. The following code borrows the constructPaymentMessage function from the signing JavaScript code above:
// this mimics the prefixing behavior of the eth_sign JSON-RPC method.
function prefixed(hash) {
    return ethereumjs.ABI.soliditySHA3(
        ["string", "bytes32"],
        ["\x19Ethereum Signed Message:\n32", hash]
    );
}
function recoverSigner(message, signature) {
    var split = ethereumjs.Util.fromRpcSig(signature);
    var publicKey = ethereumjs.Util.ecrecover(message, split.v, split.r, split.s);
    var signer = ethereumjs.Util.pubToAddress(publicKey).toString("hex");
    return signer;
}
function isValidSignature(contractAddress, amount, signature, expectedSigner) {
    var message = prefixed(constructPaymentMessage(contractAddress, amount));
    var signer = recoverSigner(message, signature);
    return signer.toLowerCase() ==
        ethereumjs.Util.stripHexPrefix(expectedSigner).toLowerCase();
}
6. Modular Contracts
A modular approach to building your contracts helps you reduce the complexity and improve the readability which will help to identify bugs and vulnerabilities during development and code review. If you specify and control the behaviour or each module in isolation, the interactions you have to consider are only those between the module specifications and not every other moving part of the contract. In the example below, the contract uses the move method of the Balances library to check that balances sent between addresses match what you expect. In this way, the Balances library provides an isolated component that properly tracks balances of accounts. It is easy to verify that the Balances library never produces negative balances or overflows and the sum of all balances is an invariant across the lifetime of the contract.
