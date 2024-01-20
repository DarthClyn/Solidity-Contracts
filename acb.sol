// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Creditbankl {
    institution[] public institutions;
    student[] public students;

    mapping(string => address) public email_to_address;
    mapping(address => uint256) public address_to_id;
    mapping(address => bool) public is_institute;

    struct institution {
        uint256 id;
        string name;
        address wallet_address;
        uint256 enrolled;
        uint256[] current_students;
        uint256[] previous_students;
        uint256[] requested_students;
    }

    struct student {
        uint256 id;
        uint256 institution_id;
        string name;
        address wallet_address;
        bool is_enrolled;
        uint256 credits;
        //uint256[] student_subjects;
        
    }

    function _1sign_up(string memory email,string memory name,string memory acc_type) public {
        require(email_to_address[email] == address(0),"error: student already exists!");
        email_to_address[email] = msg.sender;
        if (strcmp(acc_type, "student")) {
            student storage new_student = students.push();
            new_student.name = name;
            new_student.id = students.length - 1;
            new_student.wallet_address = msg.sender;
            address_to_id[msg.sender] = new_student.id;
        }
        else {
            institution storage new_institution = institutions.push();
            new_institution.name = name;
            new_institution.id = institutions.length - 1;
            new_institution.wallet_address = msg.sender;
            new_institution.current_students = new uint256[](0);
            new_institution.previous_students = new uint256[](0);
            address_to_id[msg.sender] = new_institution.id;
            is_institute[msg.sender] = true;
        }
    }


    function _2req_enrollment(uint256 institution_id) public {
        require(is_institute[msg.sender]==false, "Only student can enroll");
        require(institution_id < institutions.length, "Invalid institute ID");
        require(students[address_to_id[msg.sender]].is_enrolled==false,"Student is already enrolled");
        institutions[institution_id].requested_students.push(address_to_id[msg.sender]);
      
    }


    function _3add_student(uint256 student_id) public {
        require(is_institute[msg.sender], "Only institutes can add");
        require(student_id < students.length, "Invalid student ID");
        if(exists(student_id,institutions[address_to_id[msg.sender]].requested_students)){
            institutions[address_to_id[msg.sender]].current_students.push(student_id);
            students[student_id].institution_id =address_to_id[msg.sender];
            students[student_id].is_enrolled=true;
            rplc(student_id,institutions[address_to_id[msg.sender]].requested_students);
            institutions[address_to_id[msg.sender]].requested_students.pop();
            institutions[address_to_id[msg.sender]].enrolled++;
        }
    }



    function _4add_credit(uint256 student_id, uint256 amount) public {
        require(is_institute[msg.sender], "Only institutes can add credits");
        require(student_id < students.length, "Invalid student ID");
        require(students[student_id].institution_id==address_to_id[msg.sender],"Student is not enrolled");
        students[student_id].credits += amount;
    }



    function _5kick_student(uint256 student_id) public {
        require(is_institute[msg.sender], "Only institutes can kick");
        require(student_id < students.length, "Invalid student ID");
       // if(exists(student_id,institutions[address_to_id[msg.sender]].requested_students)){
            institutions[address_to_id[msg.sender]].previous_students.push(student_id);
            students[student_id].institution_id =0;
            students[student_id].is_enrolled=false;
            rplc(student_id,institutions[address_to_id[msg.sender]].current_students);
            institutions[address_to_id[msg.sender]].current_students.pop();
            institutions[address_to_id[msg.sender]].enrolled--;
            //}
    }


    function memcmp(bytes memory a, bytes memory b)internal pure returns (bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strcmp(string memory a, string memory b) internal pure returns (bool){
        return memcmp(bytes(a), bytes(b));
    }
    function exists(uint256 num,  uint256[] memory array) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == num) 
            {return true;}  }
        return false;
    }
    function rplc(uint256 num, uint256[] memory array) internal pure{
        uint256 temp;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == num) {
                temp = array[i];
            }
        array[i]=array[array.length-1];
        array[array.length-1]=temp;
        
    }}
    function dummy() external {
        string memory a= "aplha";
        string memory b="namecomp";
        string memory c="ins";
        string memory d="kid";
        string memory e="prsnl";
        string memory f="student";
        _1sign_up(a,b,c);
        _1sign_up(d,e,f);
    }
}
