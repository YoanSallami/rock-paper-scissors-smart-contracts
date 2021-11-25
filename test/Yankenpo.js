const { expect } = require("chai");

describe("Yankenpo contract", function () {

    let Yankenpo;
    let contractInstance;

    let owner;
    let alice;
    let bob;
    let max;

    let starting_bet;
    let round_expiration_time;

    beforeEach(async function () {
        Yankenpo = await ethers.getContractFactory("Yankenpo");

        [owner, alice, bob, max] = await ethers.getSigners();

        starting_bet = 300000;
        round_expiration_time = 60*60*5;

        contractInstance = await Yankenpo.deploy(alice.address, starting_bet, round_expiration_time);
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
            const contractInstanceFromAlice = contractInstance.connect(alice);
            await expect(contractInstanceFromAlice.cancelGame())
                .to.emit(contractInstance, 'GameCanceled')
                .withArgs(alice.address);
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

});