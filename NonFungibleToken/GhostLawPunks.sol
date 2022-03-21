//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GhostLawPunks is ERC721 {
    using SafeMath for uint256;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    mapping (address => bool) public mintrs;

    event Mint(
        uint256 indexed index,
        address indexed whom,
        uint256 fatherId
    );

    address payable internal deployer = msg.sender;

    mapping (uint256 => uint256) public ghostToOrigin;
    // Mapping from origin tokenId to their (enumerable) set of tokens
    mapping (uint256 => EnumerableSet.UintSet) private _originToGhosts;

    constructor () ERC721("Ghost LAWPunks", "GLPUNK") public {}

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    function setDeployer(address payable _deployer) external onlyDeployer {
        deployer = _deployer;
    }

    function setMintr(address _mintr,bool status) public onlyDeployer{
        mintrs[_mintr] = status;
    }

    function setBaseURI(string memory baseURI_) public onlyDeployer {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyDeployer {
        _setTokenURI(tokenId, _tokenURI);
    }

    function mint(address _to, uint256 father) public  returns(bool) {
        require(mintrs[msg.sender], "emm");

        uint _innerId = totalSupply().add(1);
        uint _tokenId = _innerId.mul(100000).add(father);


        ghostToOrigin[_tokenId] = father;
        _originToGhosts[father].add(_tokenId);

        _mint(_to, _tokenId);
        emit Mint(_tokenId, _to, father);
        return true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory base = baseURI();
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, ghostToOrigin[tokenId].toString()));
    }

    function tokensOfOwnerByPage(
        address _owner,
        uint256 _pageNo,
        uint256 _pageSize
    ) public view returns (uint256[] memory ids) {
        uint256 balance = balanceOf(_owner);
        if (balance == 0) return new uint256[](0);

        uint256 startIndex = _pageNo.mul(_pageSize);
        if (startIndex > balance) return new uint256[](0);

        uint256 idsLen = balance.sub(startIndex);
        if (idsLen > _pageSize) {
            idsLen = _pageSize;
        }

        ids = new uint256[](idsLen);

        for (uint256 i = 0; i < idsLen; ++i) {
            ids[i] = tokenOfOwnerByIndex(_owner,i + startIndex);
        }
    }

    function balanceOfOri(uint256 punkId) public view  returns (uint256) {
        return _originToGhosts[punkId].length();
    }

    function originToGhostsByIndex(uint256 punkId, uint256 index) public view returns (uint256) {
        return _originToGhosts[punkId].at(index);
    }

    function ghostsOfOriginByPage(
        uint256 _punkId,
        uint256 _pageNo,
        uint256 _pageSize
    ) public view returns (uint256[] memory ids) {
        uint256 balance = balanceOfOri(_punkId);
        if (balance == 0) return new uint256[](0);

        uint256 startIndex = _pageNo.mul(_pageSize);
        if (startIndex > balance) return new uint256[](0);

        uint256 idsLen = balance.sub(startIndex);
        if (idsLen > _pageSize) {
            idsLen = _pageSize;
        }

        ids = new uint256[](idsLen);

        for (uint256 i = 0; i < idsLen; ++i) {
            ids[i] = originToGhostsByIndex(_punkId,i + startIndex);
        }
    }

}