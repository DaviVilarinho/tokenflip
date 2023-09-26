// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.25 <0.9.0; // meu compilador...

/**
  @title Coin Flipping

  This is a simple and full of bugs Smart Contract to handle a coin flipping bet.
  The players are expected to choose 0 or 1. If both choose the same value, player 1 get the pot,
   otherwise player 2 wins.

  In this implementation very few checks are made: the exercise is to deliver a functional and secure smart contract.

  When verifying the honest behavior of participants you should consider:
            - If both are dishonest: the money is locked: the money gets stuck in the contract...forever!
            - If only one is honest: winner!
            - If both are honest: use the games rules do determine the winner

  There are easy fixes...but some are trick.
*/

import "./SimpleCommit.sol";

contract CoinFlipping {

  using SimpleCommit for SimpleCommit.CommitType;

  SimpleCommit.CommitType firstPlayer;
  SimpleCommit.CommitType secondPlayer;
  address payable firstPlayerAddress;
  address payable secondPlayerAddress;
  uint betValue; // ATT: renomeado para betValue para evitar que usasse mesmo valor que alguma keyword (como msg.value)
  address winner;

  bool hasWithdrawn; // ADC: flag para só permitir tirar o dinheiro uma vez

  bytes1 public HEADS = 0x00; // ADC: criando valor padrão para cada aposta
  bytes1 public TAILS = 0x01; // ADC: criando valor padrão para cada aposta

   constructor(bytes32 c) payable { // ATT: removido public desnecessário
     firstPlayer.commit(c);
     betValue = msg.value;
     firstPlayerAddress = payable(msg.sender); // forçando ser payable
     hasWithdrawn = false;
   }


   function joinBet(bytes32 c) public payable {
     require(msg.value == betValue, "Voce deve pagar o mesmo tanto que o player1"); // ATT: forçando ser o mesmo valor
     require(secondPlayerAddress == address(0), "Ja ha segundo player"); // ATT: Não permitir override de player2
     secondPlayer.commit(c);
     secondPlayerAddress = payable(msg.sender); // forçando ser payable
   }

   function reveal(bytes1 v,bytes32 nonce) public { // questão de compilador byte->byte1
     if (msg.sender == firstPlayerAddress) {
       firstPlayer.reveal(nonce,v);
     }
     if (msg.sender == secondPlayerAddress) {
       secondPlayer.reveal(nonce,v);
     }
   }

   function isCorrectAndValid(SimpleCommit.CommitType storage commit) private returns (bool) {
     return commit.isCorrect() && (commit.getValue() == HEADS || commit.getValue() == TAILS);
   }

   function pay() payable public { // ATT: precisa ser payable
     require(secondPlayerAddress != address(0x0), "Ninguem apostou!"); // ADC: validação de já pago
     require(hasWithdrawn == false, "Ja foi pago"); // ADC: validação de já pago
     // OBS: não é necessário require de se revelou porque falha no isCorrect
     /* antigo
      if (firstPlayer.isCorrect() && secondPlayer.isCorrect()) { // e se alguém trapacear?
       bytes1 v1 = firstPlayer.getValue(); // questão de compilador byte->byte1
       bytes1 v2 = firstPlayer.getValue(); // questão de compilador byte->byte1 // E O SECOND PLAYER??
       if (v1 == v2) {
         firstPlayerAddress.transfer(2*value);
       } else {
         secondPlayerAddress.transfer(2*value);
       }
     }
     */

     bool firstPlayerCorrectness = isCorrectAndValid(firstPlayer);
     bool secondPlayerCorrectness = isCorrectAndValid(secondPlayer);
     if (!(firstPlayerCorrectness || secondPlayerCorrectness)) {
       return; // ATT: os dois trapacearam, faça os dois perderem.
     }
     if (firstPlayerCorrectness && !secondPlayerCorrectness) { // ATT: caso segundo trapaceie sozinho
       firstPlayerAddress.transfer(2*betValue);
       return;
     }
     if (!firstPlayerCorrectness && secondPlayerCorrectness) { // ATT: caso primeiro trapaceie sozinho
       secondPlayerAddress.transfer(2*betValue);
       return;
     }
     // casos onde nenhum dos dois trapacearam
     if (firstPlayer.getValue() == secondPlayer.getValue()) {
       firstPlayerAddress.transfer(2*betValue);
       return;
     }
     secondPlayerAddress.transfer(2*betValue);
   }
}
