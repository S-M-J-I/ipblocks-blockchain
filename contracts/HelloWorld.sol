// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract HelloWorldContract {
    string word = "Hello World";

    function getWord() public view returns (string memory) {
        return word;
    }

    function setWord(string memory newWord) public returns (string memory) {
        word = newWord;
        return word;
    }
}
