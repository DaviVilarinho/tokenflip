pragma solidity >=0.4.25 <0.9.0; // corrigindo para compilador

library SimpleCommit {

  enum CommitStatesType {Waiting,Revealed}

  struct CommitType {
    bytes32 commited;
    bytes1 value;
    bool verified;
    CommitStatesType myState;

  }


  function commit(CommitType storage c,bytes32 h) public {
        c.commited = h;
        c.verified = false;
        c.myState = CommitStatesType.Waiting;
  }


  function reveal(CommitType storage c, bytes32 nonce, bytes1 v) public { // byte1 do compilador
    require (c.myState == CommitStatesType.Waiting);
    bytes32 ver = sha256(abi.encodePacked(nonce,v));
    c.myState = CommitStatesType.Revealed;
    if (ver==c.commited) {
      c.verified = true;
      c.value =v;
    }
  }

  function isCorrect(CommitType storage c) public returns (bool) {
    require (c.myState == CommitStatesType.Revealed,"Wait!");
    return c.verified;
  }

  function getValue(CommitType storage c) public returns(bytes1) { // retorno byte1
    require (c.myState == CommitStatesType.Revealed);
    require (c.verified==true);
    return c.value;
  }


}
