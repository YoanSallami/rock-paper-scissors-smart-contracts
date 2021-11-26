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
        it("Should start the game", async function() {
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
        it("Should join the game", async function() {
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
            const secretChoice0 = ROCK;
            const nonce0 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret0 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice0, nonce0]);

            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});

            await contractInstanceFromAlice.commitRound(secret0);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(ROCK, nonce0);
        });
        it("Should commit the second secret", async function() {
            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);
            await expect(contractInstanceFromAlice.commitRound(secret1))
                .to.emit(contractInstance, 'RoundCommited')
                .withArgs(1, alice.address, bob.address);
        });
        it("Should play the first round", async function() {
            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);
            await contractInstanceFromAlice.commitRound(secret1);
            await expect(contractInstanceFromBob.playRound(ROCK))
                .to.emit(contractInstance, 'RoundPlayed')
                .withArgs(1, alice.address, bob.address);
        });
        it("Should reveal the first secret", async function() {
            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);
            await contractInstanceFromAlice.commitRound(secret1);
            await contractInstanceFromBob.playRound(ROCK);
            await expect(contractInstanceFromAlice.revealRound(PAPER, nonce1))
                .to.emit(contractInstance, 'RoundRevealed')
                .withArgs(1, alice.address, bob.address);
        });
        it("Should have the right count", async function() {
            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);
            await contractInstanceFromAlice.commitRound(secret1);
            await contractInstanceFromBob.playRound(ROCK);
            await contractInstanceFromAlice.revealRound(PAPER, nonce1);
            expect(await contractInstance.player_1_count()).to.equals(2);
            expect(await contractInstance.player_2_count()).to.equals(0);
        });
        it("Should not have winner", async function() {
            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);
            await contractInstanceFromAlice.commitRound(secret1);
            await contractInstanceFromBob.playRound(ROCK);
            await contractInstanceFromAlice.revealRound(PAPER, nonce1);
            expect(await contractInstance.winner()).to.equals('0x0000000000000000000000000000000000000000');
        });
    });

    describe("Fight (3 rounds / player 1 win)", function () {
        beforeEach(async function () {
            const secretChoice0 = ROCK;
            const nonce0 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret0 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice0, nonce0]);

            const secretChoice1 = PAPER;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);

            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});

            await contractInstanceFromAlice.commitRound(secret0);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(ROCK, nonce0);

            await contractInstanceFromAlice.commitRound(secret1);
            await contractInstanceFromBob.playRound(ROCK);
            await contractInstanceFromAlice.revealRound(PAPER, nonce1);
        });
        it("Should commit the third secret", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await expect(contractInstanceFromAlice.commitRound(secret2))
                .to.emit(contractInstance, 'RoundCommited')
                .withArgs(2, alice.address, bob.address);
        });
        it("Should play the first round", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await expect(contractInstanceFromBob.playRound(PAPER))
                .to.emit(contractInstance, 'RoundPlayed')
                .withArgs(2, alice.address, bob.address);
        });
        it("Should reveal the first secret", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await expect(contractInstanceFromAlice.revealRound(CISSOR, nonce2))
                .to.emit(contractInstance, 'RoundRevealed')
                .withArgs(2, alice.address, bob.address);
        });
        it("Should have the right count", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await contractInstanceFromAlice.revealRound(CISSOR, nonce2);
            expect(await contractInstance.player_1_count()).to.equals(3);
            expect(await contractInstance.player_2_count()).to.equals(0);
        });
        it("Should have a winner", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await contractInstanceFromAlice.revealRound(CISSOR, nonce2);
            expect(await contractInstance.winner()).to.equals(alice.address);
        });
        it("Should withdraw the gain", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await contractInstanceFromAlice.revealRound(CISSOR, nonce2);
            await expect(contractInstanceFromAlice.withdrawGain())
                         .to.emit(contractInstance, 'GainWithdrawn')
                         .withArgs(alice.address, starting_bet*2);
        });
        it("Should change ethers balance", async function() {
            const secretChoice2 = CISSOR;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);
            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await contractInstanceFromAlice.revealRound(CISSOR, nonce2);
            await expect(await contractInstanceFromAlice.withdrawGain())
                .to.changeEtherBalance(alice, starting_bet*2);
        });
    });
    describe("Fight (3 rounds / player 2 win)", function () {
        beforeEach(async function () {
            const secretChoice0 = PAPER;
            const nonce0 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret0 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice0, nonce0]);

            const secretChoice1 = CISSOR;
            const nonce1 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret1 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice1, nonce1]);

            const secretChoice2 = ROCK;
            const nonce2 = "0x" + crypto.randomBytes(32).toString('hex');
            const secret2 = ethers.utils.solidityKeccak256(["uint8", "bytes32"],[secretChoice2, nonce2]);

            await contractInstance.startGame({value: starting_bet});
            await contractInstance.joinGame(bob.address, {value: starting_bet});

            await contractInstanceFromAlice.commitRound(secret0);
            await contractInstanceFromBob.playRound(CISSOR);
            await contractInstanceFromAlice.revealRound(PAPER, nonce0);

            await contractInstanceFromAlice.commitRound(secret1);
            await contractInstanceFromBob.playRound(ROCK);
            await contractInstanceFromAlice.revealRound(CISSOR, nonce1);

            await contractInstanceFromAlice.commitRound(secret2);
            await contractInstanceFromBob.playRound(PAPER);
            await contractInstanceFromAlice.revealRound(ROCK, nonce2);
        });
        it("Should have the right count", async function() {
            expect(await contractInstance.player_1_count()).to.equals(0);
            expect(await contractInstance.player_2_count()).to.equals(3);
        });
        it("Should have a winner", async function() {
            expect(await contractInstance.winner()).to.equals(bob.address);
        });
        it("Should withdraw the gain", async function() {
            await expect(contractInstanceFromBob.withdrawGain())
                         .to.emit(contractInstance, 'GainWithdrawn')
                         .withArgs(bob.address, starting_bet*2);
        });
        it("Should change ethers balance", async function() {
            await expect(await contractInstanceFromBob.withdrawGain())
                .to.changeEtherBalance(bob, starting_bet*2);
        });
    });

});