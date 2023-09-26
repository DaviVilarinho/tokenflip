// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.5;

import {CoinFlipping} from "src/TokenFlip.sol";
import {Test, console2} from "forge-std/Test.sol";

contract TokenFlipTest is Test {
    CoinFlipping public tokenFlip;
    bytes1 ownerBet;
    bytes32 defaultNonce;
    uint betValue;

    function setUp() public {
        ownerBet = 0x00;
        defaultNonce = bytes32("macaquitos");
        betValue = 100000;
    }

    function invertBet(bytes1 bet) private returns (bytes1) {
      if (bet == 0x00) {
        return 0x01;
      }
      return 0x00;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function test_ownerCanBet() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        uint ownerBalanceChange = address(ownerAddress).balance;

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(ownerBet, defaultNonce);

        assertEq(ownerBalanceChange - address(ownerAddress).balance, betValue);
    }

    function test_playerOneWins() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(ownerBet, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,ownerBet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(ownerBet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertGt(address(ownerAddress).balance - ownerBalanceChange, betValue);
    }

    function test_PlayerTwoWins() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(ownerBet, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = invertBet(ownerBet);
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(player2bet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(address(ownerAddress).balance - ownerBalanceChange, 0);
        assertEq(address(other).balance - player2BalanceBefore, betValue);
    }

    function test_PlayerOneCheatsOnValue() public {
        bytes1 cheatedValue = 0x03;
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,cheatedValue));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(cheatedValue, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = invertBet(ownerBet);
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(player2bet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(address(ownerAddress).balance - ownerBalanceChange, 0);
        assertEq(address(other).balance - player2BalanceBefore, betValue);
    }

    function test_PlayerOneCheatsOnReveal() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(0x03, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = invertBet(ownerBet);
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(player2bet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(address(ownerAddress).balance - ownerBalanceChange, 0);
        assertEq(address(other).balance - player2BalanceBefore, betValue);
    }

    function test_PlayerTwoCheatsOnReveal() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(ownerBet, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,ownerBet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(0x03, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertGt(address(ownerAddress).balance - ownerBalanceChange, betValue);
    }
    function test_PlayerTwoCheatsOnValue() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(ownerBet, defaultNonce);
        uint ownerBalanceChange = address(ownerAddress).balance;

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");

        bytes1 cheatValue = 0x03;
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,cheatValue)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(cheatValue, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertGt(address(ownerAddress).balance - ownerBalanceChange, betValue);
    }

    function test_BothCheatOnReveal() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        uint ownerBeforeBet = address(ownerAddress).balance;

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(0x03, defaultNonce);

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = invertBet(ownerBet);
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(0x03, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(ownerBeforeBet - address(ownerAddress).balance, betValue);
        assertEq(player2BalanceBefore - address(other).balance, betValue);
    }

    function test_BothCheatOnValueOnReveal() public {
        bytes1 cheatedValue = 0x03;
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,cheatedValue));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        uint ownerBeforeBet = address(ownerAddress).balance;

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(cheatedValue, defaultNonce);

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");


        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = invertBet(ownerBet);
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(0x03, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(ownerBeforeBet - address(ownerAddress).balance, betValue);
        assertEq(player2BalanceBefore - address(other).balance, betValue);
    }
    function test_BothCheatOnRevealOnValue() public {
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,ownerBet));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        uint ownerBeforeBet = address(ownerAddress).balance;

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(0x03, defaultNonce);

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");

        bytes1 cheatedValue = 0x03;

        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = cheatedValue;
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(player2bet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(ownerBeforeBet - address(ownerAddress).balance, betValue);
        assertEq(player2BalanceBefore - address(other).balance, betValue);
    }
    function test_BothCheatOnValue() public {
        bytes1 cheatedValue = 0x03;
        bytes32 ownerBetHash = sha256(abi.encodePacked(defaultNonce,cheatedValue));
        address ownerAddress = address(this);
        
        vm.deal(ownerAddress, 100 ether);

        uint ownerBeforeBet = address(ownerAddress).balance;

        tokenFlip = new CoinFlipping{value: betValue}(ownerBetHash);
        tokenFlip.reveal(cheatedValue, defaultNonce);

        address other = address(888);

        vm.deal(other, 100 ether);
        vm.startPrank(other);
        bytes32 outroNonce = bytes32("Outro nonce?");

        uint player2BalanceBefore = address(other).balance;
        bytes1 player2bet = cheatedValue;
        tokenFlip.joinBet{value: betValue}(sha256(abi.encodePacked(outroNonce,player2bet)));

        assertEq(address(tokenFlip).balance, 2 * betValue);

        tokenFlip.reveal(player2bet, outroNonce);
        vm.stopPrank();

        tokenFlip.pay();

        assertEq(ownerBeforeBet - address(ownerAddress).balance, betValue);
        assertEq(player2BalanceBefore - address(other).balance, betValue);
    }
}
