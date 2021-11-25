const { expect } = require("chai");

const crypto = require('crypto');

describe("Yankenpo contract", function () {

    let Yankenpo;
    let contractInstance;
    let contractInstanceFromAlice;
    let contractInstanceFromBob;
    let contractInstanceFromMax;

    let owner;
    let alice;
    let bob;
    let max;

    const ROCK = 0;
    const PAPER = 1;
    const CISSOR = 2;

    const access_nonce = "0x" + crypto.randomBytes(32).toString('hex');
    const access_key = ethers.utils.solidityKeccak256(["bytes32"], [access_nonce]);

    const starting_bet = 300000;
    const round_expiration_time = 60*60*5;

    beforeEach(async function () {
        Yankenpo = await ethers.getContractFactory("Yankenpo");

        [owner, alice, bob, max] = await ethers.getSigners();

        contractInstance = await Yankenpo.deploy(alice.address, access_key, starting_bet, round_expiration_time);

        contractInstanceFromAlice = contractInstance.connect(alice);
        contractInstanceFromBob = contractInstance.connect(bob);
        contractInstanceFromMax = contractInstance.connect(max);
    });

    describe("Deployment", function () {
        it("Should have the right owner", async function() {
            expect(await contractInstance.owner()).to.equal(owner.address);
        });
        it("Should have the right starting bet", async function() {
            expect(await contractInstance.starting_bet()).to.equal(starting_bet);
        });
        it("Should have the right player 1", async function() {
            expect(await contractInstance.player_1()).to.equal(alice.address);
        });
        it("Should have the right round expiration time", async function() {
            expect(await contractInstance.round_expiration_time()).to.equal(round_expiration_time);
        });
    });

    describe("Matchmaking", function () {
        it("Should start the game and emit the right event", async function() {
            await expect(contractInstance.startGame({value: starting_bet}))
                         .to.emit(contractInstance, 'GameStarted')
                         .withArgs(alice.address, starting_bet);
        });
        it("Should have the right pending bet", async function() {
            await contractInstance.startGame({value: starting_bet});
            expect(await contractInstance.pending_bet()).to.equal(starting_bet);
        });
        it("Should have the right game state", async function() {
            await contractInstance.startGame({value: starting_bet});
            expect(await contractInstance.isGameStarted()).to.equals(true);
        });
        it("Should cancel the game before joining", async function() {
            await contractInstance.startGame({value: starting_bet});
            await expect(contractInstanceFromAlice.cancelGame())
                .to.emit(contractInstance, 'GameCanceled')
                .withArgs(alice.address, starting_bet);
        })
        it("Should join the game and emit the right event", async function() {
            await contractInstance.startGame({value: starting_bet});
            await expect(contractInstance.joinGame(bob.address, {value: starting_bet}))
                .to.emit(contractInstance, 'GameReady')
                .withArgs(alice.address, bob.address, 2*starting_bet);
        });
        it("Should have the right player 2", async function() {
            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});
            expect(await contractInstance.player_2()).to.equal(bob.address);
        });
        it("Should have the right pending bet", async function() {
            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});
            expect(await contractInstance.pending_bet()).to.equal(2*starting_bet);
        });
        it("Should have the right game state", async function() {
            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});
            expect(await contractInstance.isGameReady()).to.equals(true);
        });
    });

    describe("Fight (1 round)", function () {

        beforeEach(async function () {
            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});
        });

        it("Should commit the first secret", async function() {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);
            await expect(contractInstanceFromAlice.commitRound(secret))
                .to.emit(contractInstance, 'RoundCommited')
                .withArgs(0, alice.address, bob.address);
        });
        it("Should play the first round", async function() {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);
            await contractInstanceFromAlice.commitRound(secret);
            await expect(contractInstanceFromBob.playRound(CISSOR))
                .to.emit(contractInstance, 'RoundPlayed')
                .withArgs(0, alice.address, bob.address);
        });
        it("Should reveal the first secret", async function() {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);
            await contractInstanceFromAlice.commitRound(secret);
            await contractInstanceFromBob.playRound(CISSOR);
            await expect(contractInstanceFromAlice.revealRound(ROCK, nonce))
                .to.emit(contractInstance, 'RoundRevealed')
                .withArgs(0, alice.address, bob.address);
        });
        it("Should have the right count", async function() {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);
            await contractInstanceFromAlice.commitRound(secret);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(ROCK, nonce);
            expect(await contractInstance.player_1_count()).to.equals(1);
            expect(await contractInstance.player_2_count()).to.equals(0);
        });
        it("Should not have winner", async function() {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);
            await contractInstanceFromAlice.commitRound(secret);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(ROCK, nonce);
            expect(await contractInstance.winner()).to.equals('0x0000000000000000000000000000000000000000');
        });

    });

    describe("Fight (2 rounds)", function () {
        beforeEach(async function () {
            const secretChoice = ROCK;
            const nonce = "0x" + crypto.randomBytes(32).toString('hex');
            const secret = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice, nonce]);

            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});

            await contractInstanceFromAlice.commitRound(secret);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(ROCK, nonce);
        });
    });

});