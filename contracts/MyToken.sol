// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title MyToken
 * @dev ERC-20 토큰 구현, 발행, 구매, 조회 기능 포함
 */
contract MyToken is ERC20, Ownable {
    // 토큰 가격 (1 ETH당 토큰 수)
    uint256 public tokenPrice;
    
    // 총 발행량 제한
    uint256 public maxSupply;
    
    // 구매 이벤트
    event TokensPurchased(address indexed buyer, uint256 amountOfETH, uint256 amountOfTokens);

    /**
     * @dev 컨트랙트 생성자
     * @param _name 토큰 이름
     * @param _symbol 토큰 심볼
     * @param _initialSupply 초기 발행량
     * @param _tokenPrice 토큰 가격 (1 ETH당 토큰 수)
     * @param _maxSupply 최대 발행량
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        uint256 _tokenPrice,
        uint256 _maxSupply
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        require(_initialSupply <= _maxSupply, "Initial supply cannot exceed max supply");
        
        tokenPrice = _tokenPrice;
        maxSupply = _maxSupply;
        
        // 초기 토큰을 컨트랙트 소유자에게 발행
        _mint(msg.sender, _initialSupply * 10**decimals());
    }

    /**
     * @dev 추가 토큰 발행 (소유자만 가능)
     * @param to 토큰을 받을 주소
     * @param amount 발행할 토큰 양
     */
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply * 10**decimals(), "Exceeds max supply");
        _mint(to, amount);
    }

    /**
     * @dev ETH를 보내고 토큰 구매
     */
    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        
        // 구매할 토큰 수 계산
        uint256 tokenAmount = msg.value * tokenPrice;
        
        // 최대 발행량 체크
        require(totalSupply() + tokenAmount <= maxSupply * 10**decimals(), "Exceeds max supply");
        
        // 토큰 전송
        _mint(msg.sender, tokenAmount);
        
        // 이벤트 발생
        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    /**
     * @dev 컨트랙트 잔고 확인 (소유자만 가능)
     */
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev 컨트랙트 ETH 인출 (소유자만 가능)
     */
    function withdrawETH() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
    
    /**
     * @dev 토큰 가격 업데이트 (소유자만 가능)
     * @param _newPrice 새 토큰 가격
     */
    function setTokenPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "Price must be greater than 0");
        tokenPrice = _newPrice;
    }
    
    /**
     * @dev 특정 주소의 토큰 잔액 조회
     * @param account 조회할 주소
     * @return 토큰 잔액
     */
    function checkBalance(address account) public view returns (uint256) {
        return balanceOf(account);
    }
    
    /**
     * @dev 발행된 총 토큰 양 조회
     * @return 총 공급량
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }
    
    /**
     * @dev 남은 발행 가능한 토큰 양 조회
     * @return 남은 발행 가능량
     */
    function getRemainingSupply() public view returns (uint256) {
        return (maxSupply * 10**decimals()) - totalSupply();
    }
}