# Learning Achievement Tracking Smart Contract

A comprehensive blockchain-based system for tracking educational achievements, courses, and certifications built on the Stacks blockchain using Clarity smart contract language.

## Overview

This smart contract provides a decentralized platform for educational institutions, instructors, and students to manage courses, track learning progress, award achievements, and issue verifiable certificates. All data is stored immutably on the blockchain, ensuring transparency and preventing fraud.

## Features

### Course Management
- Create and manage courses with prerequisites
- Set enrollment limits and difficulty levels
- Track student progress and completion
- Instructor verification system

### Student Enrollment
- Enroll in courses with prerequisite checking
- Pay enrollment fees in STX
- Track progress and completion status
- Automated certificate issuance

### Achievement System
- Create custom achievements with point values
- Award achievements to students
- Level progression based on total points
- Category-based achievement organization

### Certificate Issuance
- Issue tamper-proof certificates
- Verification hash generation
- Certificate revocation capability
- Grade and score tracking

### Review System
- Student course reviews and ratings
- Instructor reputation tracking
- Quality assurance metrics

### Administrative Controls
- Contract pause/unpause functionality
- Enrollment fee management
- Instructor verification
- Owner-only administrative functions

## Contract Architecture

### Data Structures

#### Courses
- Course ID, name, description
- Instructor, credits, difficulty level
- Prerequisites and enrollment limits
- Activity status and timestamps

#### Enrollments
- Student-course relationships
- Progress tracking (0-100%)
- Status: enrolled, in-progress, completed, dropped
- Final scores and completion dates

#### Achievements
- Achievement definitions with points
- Categories and requirements
- Student-achievement mappings
- Verification and scoring

#### Certificates
- Unique certificate IDs
- Student, course, and achievement links
- Verification hashes
- Revocation status

#### Profiles
- Student profiles with credits, points, and levels
- Instructor profiles with course counts and ratings
- Reputation and activity tracking

## Constants

```clarity
MAX_COURSE_NAME_LENGTH: 100 characters
MAX_DESCRIPTION_LENGTH: 500 characters
MIN_PASSING_SCORE: 60
MAX_SCORE: 100
DEFAULT_ENROLLMENT_FEE: 1,000,000 microSTX (1 STX)
```

## Error Codes

| Code | Description |
|------|-------------|
| 1000 | Unauthorized access |
| 1001 | Resource not found |
| 1002 | Resource already exists |
| 1003 | Invalid input provided |
| 1004 | Insufficient balance |
| 1005 | Course not active |
| 1006 | Prerequisites not met |
| 1007 | Achievement locked |
| 1008 | Invalid score |
| 1009 | Enrollment closed |

## Public Functions

### Course Management

#### `create-course`
Creates a new course with specified parameters.
```clarity
(create-course name description credits difficulty-level prerequisites max-enrollment)
```

#### `update-course`
Updates course information (instructor only).
```clarity
(update-course course-id name description is-active)
```

### Enrollment

#### `enroll-in-course`
Enrolls a student in a course with fee payment.
```clarity
(enroll-in-course course-id)
```

#### `update-progress`
Updates student progress in a course (instructor only).
```clarity
(update-progress student course-id progress)
```

### Achievements

#### `create-achievement`
Creates a new achievement definition (owner only).
```clarity
(create-achievement name description category points requirements)
```

#### `award-achievement`
Awards an achievement to a student.
```clarity
(award-achievement student achievement-id score notes)
```

### Certificates

#### `issue-certificate`
Issues a certificate to a student upon course completion.
```clarity
(issue-certificate student course-id final-score grade)
```

#### `revoke-certificate`
Revokes a previously issued certificate.
```clarity
(revoke-certificate certificate-id)
```

### Reviews

#### `submit-course-review`
Allows completed students to review courses.
```clarity
(submit-course-review course-id rating review)
```

### Administrative

#### `pause-contract` / `unpause-contract`
Emergency pause functionality (owner only).

#### `set-enrollment-fee`
Updates the enrollment fee (owner only).

#### `verify-instructor`
Verifies instructor credentials (owner only).

## Read-Only Functions

### Data Retrieval
- `get-course(course-id)` - Retrieve course information
- `get-enrollment(student, course-id)` - Get enrollment details
- `get-achievement(achievement-id)` - Get achievement definition
- `get-student-achievement(student, achievement-id)` - Get earned achievement
- `get-certificate(certificate-id)` - Retrieve certificate data
- `get-student-profile(student)` - Get student profile
- `get-instructor-profile(instructor)` - Get instructor profile
- `get-course-review(student, course-id)` - Get course review

### Utility Functions
- `get-contract-info()` - Get contract statistics and settings
- `verify-certificate(certificate-id)` - Verify certificate authenticity

## Level System

Students progress through levels based on total achievement points:

| Level | Points Required |
|-------|----------------|
| 1 | 0-499 |
| 2 | 500-1,999 |
| 3 | 2,000-4,999 |
| 4 | 5,000-9,999 |
| 5 | 10,000+ |

## Usage Examples

### Creating a Course
```clarity
(contract-call? .learning-contract create-course 
  "Introduction to Blockchain" 
  "Learn the fundamentals of blockchain technology"
  u3 
  "Beginner" 
  (list) 
  u50)
```

### Enrolling in a Course
```clarity
(contract-call? .learning-contract enroll-in-course u1)
```

### Issuing a Certificate
```clarity
(contract-call? .learning-contract issue-certificate 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u1 
  u85 
  "A")
```

## Security Features

- **Authorization Controls**: Role-based access for different functions
- **Input Validation**: Comprehensive validation of all inputs
- **Prerequisites Checking**: Automated prerequisite verification
- **Balance Verification**: STX balance checks before enrollment
- **Certificate Verification**: Cryptographic hashes for certificate authenticity
- **Revocation System**: Ability to revoke certificates if needed

## Gas Optimization

The contract is optimized for gas efficiency through:
- Efficient data structures using maps
- Minimal external calls
- Batch operations where possible
- Optimized conditional logic

## Integration Guide

### For Educational Institutions
1. Deploy the contract with institution as owner
2. Verify instructor accounts
3. Set appropriate enrollment fees
4. Create achievement frameworks

### For Instructors
1. Get verified by contract owner
2. Create courses with appropriate prerequisites
3. Monitor student enrollment and progress
4. Issue certificates upon completion

### For Students
1. Browse available courses
2. Ensure prerequisites are met
3. Pay enrollment fee and enroll
4. Complete coursework and receive certificates

## Events and Monitoring

While Clarity doesn't have traditional events, the contract provides comprehensive read-only functions for monitoring:
- Course enrollment statistics
- Student progress tracking
- Achievement distribution
- Certificate issuance rates

## Upgrade Path

The contract includes administrative functions for:
- Pausing operations during maintenance
- Updating enrollment fees
- Managing instructor verification
- Emergency response capabilities