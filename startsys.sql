-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 08, 2026 at 06:03 PM
-- Server version: 10.11.16-MariaDB
-- PHP Version: 8.5.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `startsys`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_committee_members` (IN `p_committee_id` INT)   BEGIN

    SELECT
        c.Committee_Id AS Committee_ID,
        c.Committee_Name,
        d.Department_Name,

        m.START_ID,
        m.First_Name,
        m.Last_Name,
        m.University,
        m.Program,
        m.Region,

        r.Role_Title,
        r.Role_Level,

        mr.Academic_Year,
        mr.Status

    FROM membership_record AS mr

    INNER JOIN members AS m
        ON mr.START_ID = m.START_ID

    INNER JOIN committee AS c
        ON mr.Committee_ID = c.Committee_Id

    LEFT JOIN department AS d
        ON c.Department_Id = d.Department_ID

    LEFT JOIN `role` AS r
        ON mr.Role_ID = r.Role_Id

    WHERE mr.Committee_ID = p_committee_id
      AND LOWER(TRIM(mr.Status)) = 'accepted'

    ORDER BY
        mr.Academic_Year DESC,
        r.Role_Level,
        m.Last_Name;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_membership_statistics_by_academic_year` (IN `p_academic_year` VARCHAR(9))   BEGIN

    SELECT
        p_academic_year AS Academic_Year,

        COUNT(*) AS Total_Membership_Records,

        COUNT(DISTINCT START_ID) AS Unique_Member_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(Status)) = 'accepted'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Accepted_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(Status)) = 'rejected'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Rejected_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(Status)) = 'pending'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Pending_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN Status IS NULL OR TRIM(Status) = ''
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Unspecified_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(Status)) NOT IN
                         ('accepted', 'rejected', 'pending')
                     AND Status IS NOT NULL
                     AND TRIM(Status) <> ''
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Other_Status_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(Status))
                         IN ('accepted', 'rejected')
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Decided_Record_Count,

        ROUND(
            COALESCE(
                SUM(
                    CASE
                        WHEN LOWER(TRIM(Status)) = 'accepted'
                        THEN 1 ELSE 0
                    END
                ), 0
            ) * 100.0 /
            NULLIF(
                COALESCE(
                    SUM(
                        CASE
                            WHEN LOWER(TRIM(Status))
                                 IN ('accepted', 'rejected')
                            THEN 1 ELSE 0
                        END
                    ), 0
                ), 0
            ), 2
        ) AS Acceptance_Rate_Percent,

        ROUND(
            COALESCE(
                SUM(
                    CASE
                        WHEN LOWER(TRIM(Status)) = 'rejected'
                        THEN 1 ELSE 0
                    END
                ), 0
            ) * 100.0 /
            NULLIF(
                COALESCE(
                    SUM(
                        CASE
                            WHEN LOWER(TRIM(Status))
                                 IN ('accepted', 'rejected')
                            THEN 1 ELSE 0
                        END
                    ), 0
                ), 0
            ), 2
        ) AS Rejection_Rate_Percent

    FROM membership_record

    WHERE Academic_Year = p_academic_year;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_members_by_academic_year` (IN `p_academic_year` VARCHAR(9))   BEGIN

    SELECT
        mr.Record_ID,
        m.START_ID,
        m.First_Name,
        m.Last_Name,
        m.Middle_Name,
        m.Suffix,
        m.Sex,
        m.Date_of_Birth,
        m.University,
        m.Year_Level,
        m.Program,
        c.Committee_Name,
        r.Role_Title,
        r.Role_Level,
        mr.Academic_Year,
        mr.Status

    FROM membership_record AS mr

    INNER JOIN members AS m
        ON mr.START_ID = m.START_ID

    LEFT JOIN committee AS c
        ON mr.Committee_ID = c.Committee_Id

    LEFT JOIN `role` AS r
        ON mr.Role_ID = r.Role_Id

    WHERE mr.Academic_Year = p_academic_year

    ORDER BY
        m.Last_Name,
        m.First_Name,
        c.Committee_Name;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_members_by_region` (IN `p_region` VARCHAR(100))   BEGIN

    SELECT
        START_ID,
        First_Name,
        Last_Name,
        Middle_Name,
        Suffix,
        Sex,
        Date_of_Birth,
        Age,
        Contact_Number,
        Email_Address,
        Region,
        Province,
        `Municipality/City`,
        University,
        Year_Level,
        Program,
        `Scholarship Type`,
        `Year Awarded`

    FROM members

    WHERE LOWER(TRIM(Region)) = LOWER(TRIM(p_region))

    ORDER BY
        Province,
        Last_Name,
        First_Name;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_rejected_members` ()   BEGIN

    SELECT
        mr.Record_ID,
        m.START_ID,
        m.First_Name,
        m.Last_Name,
        m.University,
        m.Program,
        m.Region,

        c.Committee_Name,
        r.Role_Title,
        r.Role_Level,

        mr.Academic_Year,
        mr.Status

    FROM membership_record AS mr

    INNER JOIN members AS m
        ON mr.START_ID = m.START_ID

    LEFT JOIN committee AS c
        ON mr.Committee_ID = c.Committee_Id

    LEFT JOIN `role` AS r
        ON mr.Role_ID = r.Role_Id

    WHERE LOWER(TRIM(mr.Status)) = 'rejected'

    ORDER BY
        mr.Academic_Year DESC,
        m.Last_Name,
        m.First_Name;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_university_acceptance_statistics` (IN `p_university` VARCHAR(150))   BEGIN

    SELECT
        TRIM(m.University) AS University,

        COUNT(DISTINCT m.START_ID)
            AS Total_Registered_Members,

        COUNT(mr.Record_ID)
            AS Total_Membership_Records,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(mr.Status)) = 'accepted'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Accepted_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(mr.Status)) = 'rejected'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Rejected_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(mr.Status)) = 'pending'
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Pending_Record_Count,

        COALESCE(
            SUM(
                CASE
                    WHEN LOWER(TRIM(mr.Status))
                         IN ('accepted', 'rejected')
                    THEN 1 ELSE 0
                END
            ), 0
        ) AS Decided_Record_Count,

        ROUND(
            COALESCE(
                SUM(
                    CASE
                        WHEN LOWER(TRIM(mr.Status)) = 'accepted'
                        THEN 1 ELSE 0
                    END
                ), 0
            ) * 100.0 /
            NULLIF(
                COALESCE(
                    SUM(
                        CASE
                            WHEN LOWER(TRIM(mr.Status))
                                 IN ('accepted', 'rejected')
                            THEN 1 ELSE 0
                        END
                    ), 0
                ), 0
            ), 2
        ) AS Acceptance_Rate_Percent,

        ROUND(
            COALESCE(
                SUM(
                    CASE
                        WHEN LOWER(TRIM(mr.Status)) = 'rejected'
                        THEN 1 ELSE 0
                    END
                ), 0
            ) * 100.0 /
            NULLIF(
                COALESCE(
                    SUM(
                        CASE
                            WHEN LOWER(TRIM(mr.Status))
                                 IN ('accepted', 'rejected')
                            THEN 1 ELSE 0
                        END
                    ), 0
                ), 0
            ), 2
        ) AS Rejection_Rate_Percent

    FROM members AS m

    LEFT JOIN membership_record AS mr
        ON m.START_ID = mr.START_ID

    WHERE LOWER(TRIM(m.University)) =
          LOWER(TRIM(p_university))

    GROUP BY TRIM(m.University);

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_search_member_by_start_id` (IN `p_start_id` VARCHAR(20))   BEGIN

    SELECT
        m.START_ID,
        m.First_Name,
        m.Last_Name,
        m.Middle_Name,
        m.Suffix,
        m.Sex,
        m.Date_of_Birth,
        m.Age,
        m.Contact_Number,
        m.Email_Address,
        m.Region,
        m.Province,
        m.`Municipality/City`,
        m.University,
        m.Year_Level,
        m.Program,
        m.`Scholarship Type`,
        m.`Year Awarded`,

        mr.Record_ID,
        mr.Academic_Year,
        mr.Status,

        c.Committee_Name,
        r.Role_Title,
        r.Role_Level

    FROM members AS m

    LEFT JOIN membership_record AS mr
        ON m.START_ID = mr.START_ID

    LEFT JOIN committee AS c
        ON mr.Committee_ID = c.Committee_Id

    LEFT JOIN `role` AS r
        ON mr.Role_ID = r.Role_Id

    WHERE m.START_ID = p_start_id

    ORDER BY mr.Academic_Year DESC;

END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `committee`
--

CREATE TABLE `committee` (
  `Committee_Id` int(11) NOT NULL,
  `Department_Id` int(11) DEFAULT NULL,
  `Committee_Name` varchar(75) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `committee`
--

INSERT INTO `committee` (`Committee_Id`, `Department_Id`, `Committee_Name`) VALUES
(1, 1, 'Executive Leadership'),
(2, 2, 'Tech Education Committee'),
(3, 2, 'Tech Secretariat'),
(4, 5, 'Finance Committee'),
(5, 4, 'Graphics Committee'),
(6, 4, 'Copywriting Committee'),
(7, 4, 'Socials Committee'),
(8, 4, 'Media Committee'),
(9, 3, 'Partnership Committee'),
(10, 3, 'Sponsorship Committee'),
(11, 3, 'Connect and Coordinate Committee'),
(12, 6, 'Regional Representatives'),
(13, 7, 'Programs Committee'),
(14, 7, 'Logistics Committee'),
(15, 8, 'General Member'),
(16, 2, 'Technology'),
(17, 3, 'Communications'),
(18, 4, 'Marketing'),
(19, 5, 'Finance'),
(20, 6, 'Community and Regional Relations'),
(21, 7, 'Events');

-- --------------------------------------------------------

--
-- Table structure for table `department`
--

CREATE TABLE `department` (
  `Department_ID` int(11) NOT NULL,
  `Department_Name` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `department`
--

INSERT INTO `department` (`Department_ID`, `Department_Name`) VALUES
(1, 'Executive Leadership'),
(2, 'Technology'),
(3, 'Communications'),
(4, 'Marketing'),
(5, 'Finance'),
(6, 'Community and Regional Relations'),
(7, 'Events'),
(8, 'General Member');

-- --------------------------------------------------------

--
-- Table structure for table `members`
--

CREATE TABLE `members` (
  `START_ID` varchar(20) NOT NULL,
  `First_Name` varchar(50) DEFAULT NULL,
  `Last_Name` varchar(50) DEFAULT NULL,
  `Middle_Name` varchar(50) DEFAULT NULL,
  `Suffix` varchar(10) DEFAULT NULL,
  `Sex` varchar(10) DEFAULT NULL,
  `Date_of_Birth` date DEFAULT NULL,
  `Age` tinyint(3) UNSIGNED DEFAULT NULL,
  `Contact_Number` varchar(15) DEFAULT NULL,
  `Email_Address` varchar(100) DEFAULT NULL,
  `Region` varchar(100) DEFAULT NULL,
  `Province` varchar(100) DEFAULT NULL,
  `Municipality/City` varchar(100) DEFAULT NULL,
  `University` varchar(150) DEFAULT NULL,
  `Year_Level` tinyint(3) UNSIGNED DEFAULT NULL,
  `Program` varchar(150) DEFAULT NULL,
  `Scholarship Type` varchar(50) DEFAULT NULL,
  `Year Awarded` year(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `members`
--

INSERT INTO `members` (`START_ID`, `First_Name`, `Last_Name`, `Middle_Name`, `Suffix`, `Sex`, `Date_of_Birth`, `Age`, `Contact_Number`, `Email_Address`, `Region`, `Province`, `Municipality/City`, `University`, `Year_Level`, `Program`, `Scholarship Type`, `Year Awarded`) VALUES
('START-01-25-00069', 'Carl', 'Flores', 'Garcia', '', 'Male', '2007-11-16', 19, '9755082216', 'carl.flores52@example.com', 'Region I (Ilocos Region)', 'Ilocos Norte', 'Batac City', 'Batangas State University The National Engineering University ARASOF-Nasugbu', 2, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2025'),
('START-01-25-00140', 'Nicole', 'Dizon', 'Dizon', '', 'Female', '2006-08-02', 20, '9120818280', 'nicole.dizon47@example.com', 'Region I (Ilocos Region)', 'Pangasinan', 'Lingayen', 'University of Mindanao - Matina Campus', 2, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2025'),
('START-01-25-00152', 'Kimberly', 'Chuaunsu', 'Del Rosario', '', 'Female', '2007-08-31', 19, '9500097139', 'kimberly.chuaunsu64@example.com', 'Region I (Ilocos Region)', 'Ilocos Norte', 'Laoag City', 'Cagayan State University- Carig Campus', 1, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2026'),
('START-01-26-00073', 'James', 'Bulanadi', 'Rodriguez', 'IV', 'Male', '2004-12-05', 22, '9119812625', 'james.bulanadi39@example.com', 'Region I (Ilocos Region)', 'Pangasinan', 'Lingayen', 'Polytechnic University of the Philippines - Taguig Campus', 4, 'Industrial Management Engineering – Information Technology', 'JLSS - RA 7687', '2025'),
('START-01-26-00107', 'Mary', 'Gonzales', 'Chuaunsu', '', 'Female', '2003-07-12', 23, '9847360215', 'mary.gonzales20@example.com', 'Region I (Ilocos Region)', 'Pangasinan', 'Urdaneta City', 'Southern Luzon State University - Lucban', 5, 'Information Technology', 'RA 7687', '2022'),
('START-02-24-00020', 'Rhea', 'Navarro', 'Tomas', '', 'Female', '2008-07-09', 18, '9146679661', 'rhea.navarro46@example.com', 'Region II (Cagayan Valley)', 'Isabela', 'Cauayan City', 'Bicol University- West Campus', 1, 'Information and Communications Technology', 'Merit', '2026'),
('START-02-24-00075', 'John', 'Rodriguez', 'Cruz', '', 'Male', '2007-04-05', 19, '9222840360', 'john.rodriguez87@example.com', 'Region II (Cagayan Valley)', 'Isabela', 'Cauayan City', 'University of the Cordilleras - Governor Pack Road', 2, 'Statistics', 'RA 7687', '2025'),
('START-02-24-00087', 'Ana', 'Chuaunsu', 'Bautista', '', 'Female', '2004-01-14', 22, '9239416443', 'ana.chuaunsu31@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'Central Mindanao University', 4, 'Information Systems', 'Merit', '2023'),
('START-02-24-00122', 'Ryan', 'Mendoza', 'Navarro', '', 'Male', '2006-05-23', 20, '9826452406', 'ryan.mendoza40@example.com', 'Region II (Cagayan Valley)', 'Isabela', 'Cauayan City', 'Batangas State University - The National Engineering University', 3, 'Electronics and Communication Engineering', 'JLSS - RA 7687', '2026'),
('START-02-25-00058', 'Juan', 'Dizon', 'Gomez', '', 'Male', '2006-08-13', 20, '9246453809', 'juan.dizon74@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'University of Mindanao - Matina Campus', 2, 'Applied Mathematics', 'RA 7687', '2025'),
('START-02-25-00084', 'Jasmine', 'Villanueva', 'Tomas', '', 'Female', '2008-06-30', 18, '9445230176', 'jasmine.villanueva71@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'Camarines Sur Polytechnic Colleges', 1, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2026'),
('START-02-25-00104', 'Maria', 'Torres', 'Del Rosario', '', 'Female', '2007-06-21', 19, '9571793636', 'maria.torres98@example.com', 'Region II (Cagayan Valley)', 'Isabela', 'Cauayan City', 'Mindanao State University - Iligan Institute of Technology', 1, 'Computer Science', 'RA 7687', '2026'),
('START-02-25-00121', 'Kimberly', 'Del Rosario', 'Bulanadi', '', 'Female', '2007-05-27', 19, '9334639259', 'kimberly.del rosario95@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'Cebu Technological University', 2, 'Electronics and Communication Engineering', 'RA 7687', '2025'),
('START-02-26-00149', 'Ian', 'Rodriguez', 'Soriano', 'Jr.', 'Male', '2006-05-03', 20, '9635374415', 'ian.rodriguez4@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'Mindanao State University - Main Campus, Marawi City', 2, 'Electronics and Communication Engineering', 'RA 7687', '2025'),
('START-02-26-00151', 'Paul', 'Bautista', 'Valmonte', '', 'Male', '2005-04-27', 21, '9709467658', 'paul.bautista17@example.com', 'Region II (Cagayan Valley)', 'Cagayan', 'Aparri', 'Tarlac State University - San Isidro Campus', 3, 'Industrial Management Engineering – Information Technology', 'Merit', '2024'),
('START-03-24-00072', 'Ana', 'Villanueva', 'Soriano', '', 'Female', '2007-05-15', 19, '9507951445', 'ana.villanueva70@example.com', 'Region III (Central Luzon)', 'Pampanga', 'San Fernando City', 'Ateneo de Davao University - Jacinto Campus', 1, 'Computer Science', 'RA 7687', '2026'),
('START-03-25-00071', 'Christine', 'Del Rosario', 'Gonzales', '', 'Female', '2006-12-20', 20, '9646772011', 'christine.del rosario97@example.com', 'Region III (Central Luzon)', 'Pampanga', 'Angeles City', 'Cebu Institute of Technology University parking', 2, 'Management Information Systems', 'Merit', '2025'),
('START-03-25-00077', 'Kimberly', 'Flores', 'Flores', '', 'Female', '2004-07-26', 22, '9977891780', 'kimberly.flores53@example.com', 'Region III (Central Luzon)', 'Nueva Ecija', 'Cabanatuan City', 'Batangas State University - The National Engineering University', 4, 'Computer Engineering', 'RA 7687', '2023'),
('START-03-26-00115', 'Maria', 'Flores', 'Ramos', '', 'Female', '2008-04-26', 18, '9209756992', 'maria.flores4@example.com', 'Region III (Central Luzon)', 'Pampanga', 'San Fernando City', 'University of the Philippines Tacloban', 1, 'Management Information Systems', 'Merit', '2026'),
('START-03-26-00136', 'Juan', 'Gomez', 'Chuaunsu', '', 'Male', '2004-05-17', 22, '9765451502', 'juan.gomez35@example.com', 'Region III (Central Luzon)', 'Pampanga', 'San Fernando City', 'Polytechnic University of the Philippines - Sta. Mesa, Manila', 4, 'Electronics and Communication Engineering', 'JLSS - RA 7687', '2025'),
('START-04-24-00017', 'Michelle', 'Flores', 'Reyes', '', 'Female', '2007-03-26', 19, '9506962141', 'michelle.flores20@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Batangas City', 'Surigao Del Norte State University - Main Campus', 2, 'Information Technology', 'Merit', '2025'),
('START-04-24-00042', 'Samantha', 'Cruz', 'Soriano', '', 'Female', '2005-12-07', 21, '9902019095', 'samantha.cruz33@example.com', 'Region IV-A (CALABARZON)', 'Cavite', 'Bacoor City', 'Southern Luzon State University', 3, 'Management Information Systems', 'Merit', '2024'),
('START-04-24-00043', 'Marian', 'Bautista', 'Garcia', '', 'Female', '2006-09-24', 20, '9748063833', 'marian.bautista92@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Batangas City', 'Ateneo de Zamboanga University', 3, 'Management Information Systems', 'JLSS - Merit', '2026'),
('START-04-24-00105', 'Angelo', 'Santos', 'Torres', '', 'Male', '2003-08-14', 23, '9185431872', 'angelo.santos52@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Lipa City', 'Nueva Vizcaya State University, Bayombong Campus', 5, 'Information and Communications Technology', 'RA 7687', '2022'),
('START-04-24-00142', 'Francis', 'Aquino', 'Torres', '', 'Male', '2005-01-10', 21, '9847601225', 'francis.aquino36@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Lipa City', 'University of Southeastern Philippines', 4, 'Statistics', 'JLSS - Merit', '2025'),
('START-04-24-00143', 'David', 'Rodriguez', 'Gonzales', '', 'Male', '2005-02-08', 21, '9957354049', 'david.rodriguez98@example.com', 'Region IV-A (CALABARZON)', 'Cavite', 'Bacoor City', 'Cavite State University - Indang', 4, 'Applied Mathematics', 'JLSS - RA 7687', '2025'),
('START-04-25-00038', 'Mary', 'Villanueva', 'Bulanadi', '', 'Female', '2005-08-01', 21, '9429645111', 'mary.villanueva71@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Lipa City', 'Polytechnic University of the Philippines - Manila Campus', 3, 'Electronics and Communication Engineering', 'RA 7687', '2024'),
('START-04-26-00067', 'Andrea', 'Gomez', 'Navarro', '', 'Female', '2004-07-27', 22, '9881382110', 'andrea.gomez9@example.com', 'Region IV-A (CALABARZON)', 'Cavite', 'Dasmarinas City', 'St. Paul University Dumaguete', 5, 'Information and Communications Technology', 'JLSS - RA 7687', '2024'),
('START-04-26-00148', 'Paul', 'Ramos', 'Soriano', '', 'Male', '2006-06-20', 20, '9891524679', 'paul.ramos46@example.com', 'Region IV-A (CALABARZON)', 'Batangas', 'Batangas City', 'Tarlac State University', 2, 'Applied Mathematics', 'Merit', '2025'),
('START-05-24-00005', 'Nicole', 'Aquino', 'Perez', '', 'Female', '2006-02-13', 20, '9673581540', 'nicole.aquino90@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Iriga City', 'Visayas State University - Isabel Campus', 3, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2024'),
('START-05-24-00015', 'David', 'Dizon', 'Mendoza', '', 'Male', '2008-09-21', 18, '9666402556', 'david.dizon2@example.com', 'Region V (Bicol Region)', 'Albay', 'Tabaco City', 'Bulacan State University, Malolos Campus', 1, 'Information Technology Systems', 'RA 7687', '2026'),
('START-05-24-00022', 'Jessa', 'Ocampo', 'Soriano', '', 'Female', '2007-01-28', 19, '9111493892', 'jessa.ocampo97@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Iriga City', 'Bulacan State University of Malolos', 2, 'Statistics', 'RA 7687', '2025'),
('START-05-24-00138', 'Angelica', 'Aquino', 'Aquino', '', 'Female', '2005-03-02', 21, '9411183316', 'angelica.aquino74@example.com', 'Region V (Bicol Region)', 'Albay', 'Legazpi City', 'Xavier University - Ateneo de Cagayan', 4, 'Management Information Systems', 'Merit', '2023'),
('START-05-24-00146', 'Rafael', 'Flores', 'Rodriguez', '', 'Male', '2004-08-16', 22, '9150649217', 'rafael.flores95@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Naga City', 'Ateneo de Naga University', 5, 'Applied Mathematics', 'JLSS - RA 7687', '2024'),
('START-05-25-00027', 'Sarah', 'Ocampo', 'Garcia', '', 'Female', '2005-07-03', 21, '9369307067', 'sarah.ocampo23@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Iriga City', 'Baliuag UniveryCavite State University - Carmona', 4, 'Information Technology Systems', 'JLSS - RA 7687', '2025'),
('START-05-25-00083', 'Andrea', 'Ramos', 'Chuaunsu', '', 'Female', '2007-04-06', 19, '9105968470', 'andrea.ramos27@example.com', 'Region V (Bicol Region)', 'Albay', 'Legazpi City', 'Mindanao States University - Iligan Institute of Technology', 1, 'Information Technology Systems', 'RA 7687', '2026'),
('START-05-25-00091', 'Ana', 'Perez', 'Castillo', '', 'Female', '2004-08-20', 22, '9538244858', 'ana.perez36@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Naga City', 'University of Batangas - Batangas City Campus', 5, 'Electronics and Communication Engineering', 'Merit', '2022'),
('START-05-25-00127', 'Ian', 'Gomez', 'Reyes', '', 'Male', '2004-10-08', 22, '9515923694', 'ian.gomez9@example.com', 'Region V (Bicol Region)', 'Camarines Sur', 'Iriga City', 'Bulacan State University - Malolos Campus (Main Campus)', 4, 'Information Technology Systems', 'RA 7687', '2023'),
('START-05-26-00025', 'Sofia', 'Lopez', 'Soriano', '', 'Female', '2005-01-07', 21, '9269982353', 'sofia.lopez68@example.com', 'Region V (Bicol Region)', 'Albay', 'Tabaco City', 'Eastern Visayas State University', 4, 'Statistics', 'RA 7687', '2023'),
('START-06-24-00002', 'Angelo', 'Soriano', 'Castillo', '', 'Male', '2005-08-05', 21, '9426728702', 'angelo.soriano28@example.com', 'Region VI (Western Visayas)', 'Capiz', 'Panay', 'Pampanga State University - Main Campus Bacolor', 3, 'Information Systems', 'RA 7687', '2024'),
('START-06-24-00010', 'Ivan', 'Torres', 'Rodriguez', '', 'Male', '2006-01-13', 20, '9826603146', 'ivan.torres86@example.com', 'Region VI (Western Visayas)', 'Iloilo', 'Iloilo City', 'Cebu Institute of Technology University', 2, 'Computer Science', 'Merit', '2025'),
('START-06-24-00039', 'Sofia', 'Cruz', 'Lopez', '', 'Female', '2007-02-13', 19, '9402756284', 'sofia.cruz25@example.com', 'Region VI (Western Visayas)', 'Iloilo', 'Iloilo City', 'University of the Cordilleras - Governor Pack Road', 2, 'Information Technology Systems', 'RA 7687', '2025'),
('START-06-24-00064', 'Sofia', 'Gomez', 'Soriano', '', 'Female', '2008-09-13', 18, '9233684363', 'sofia.gomez13@example.com', 'Region VI (Western Visayas)', 'Iloilo', 'Iloilo City', 'Polytechnic University of the Philippines - Taguig Campus', 1, 'Industrial Management Engineering – Information Technology', 'Merit', '2026'),
('START-06-25-00076', 'Jasmine', 'Mendoza', 'Villanueva', '', 'Female', '2007-05-03', 19, '9764673688', 'jasmine.mendoza92@example.com', 'Region VI (Western Visayas)', 'Iloilo', 'Iloilo City', 'Technological University of the Philippines - Taguig Campus', 2, 'Electronics and Communication Engineering', 'RA 7687', '2025'),
('START-06-25-00131', 'Jasmine', 'Del Rosario', 'Villanueva', '', 'Female', '2006-06-27', 20, '9854758976', 'jasmine.del rosario14@example.com', 'Region VI (Western Visayas)', 'Capiz', 'Panay', 'University of Southeastern Philippines', 3, 'Applied Mathematics', 'JLSS - Merit', '2026'),
('START-06-26-00114', 'Kevin', 'Valmonte', 'Chuaunsu', 'III', 'Male', '2007-03-05', 19, '9353247925', 'kevin.valmonte12@example.com', 'Region VI (Western Visayas)', 'Capiz', 'Roxas City', 'University of Rizal System - Antipolo', 1, 'Information and Communications Technology', 'Merit', '2026'),
('START-06-26-00118', 'Christian', 'Valmonte', 'Santos', '', 'Male', '2005-09-11', 21, '9513521253', 'christian.valmonte50@example.com', 'Region VI (Western Visayas)', 'Iloilo', 'Iloilo City', 'Southern Luzon State University - Main Campus', 4, 'Management Information Systems', 'JLSS - Merit', '2025'),
('START-07-24-00026', 'Gabriel', 'Dizon', 'Valmonte', 'III', 'Male', '2008-08-31', 18, '9617799621', 'gabriel.dizon64@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Cebu City', 'University of Rizal System - Antipolo', 1, 'Computer Engineering', 'RA 7687', '2026'),
('START-07-24-00036', 'Angelica', 'Rodriguez', 'Rodriguez', '', 'Female', '2007-05-01', 19, '9179962586', 'angelica.rodriguez88@example.com', 'Region VII (Central Visayas)', 'Bohol', 'Tagbilaran City', 'Batangas State University - The National Engineering University Alangilan Campus', 2, 'Computer Engineering', 'Merit', '2025'),
('START-07-24-00044', 'Michael', 'Valmonte', 'Mendoza', '', 'Male', '2008-11-09', 18, '9580420503', 'michael.valmonte15@example.com', 'Region VII (Central Visayas)', 'Bohol', 'Tagbilaran City', 'Bulacan State University- Malolos Campus', 1, 'Information Technology', 'RA 7687', '2026'),
('START-07-24-00048', 'Angelica', 'Reyes', 'Castillo', '', 'Female', '2006-10-12', 20, '9401117746', 'angelica.reyes46@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Cebu City', 'Southern Luzon State University - Main', 2, 'Information Systems', 'Merit', '2025'),
('START-07-24-00068', 'John', 'Flores', 'Bautista', '', 'Male', '2006-08-01', 20, '9923096889', 'john.flores5@example.com', 'Region VII (Central Visayas)', 'Bohol', 'Tagbilaran City', 'Marinduque State University', 2, 'Computer Science', 'RA 7687', '2025'),
('START-07-24-00070', 'Maria', 'Chuaunsu', 'Tomas', '', 'Female', '2005-01-08', 21, '9218039906', 'maria.chuaunsu87@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Cebu City', 'Polytechnic University of the Philippines - Sta. Mesa, Manila', 3, 'Information Technology', 'Merit', '2024'),
('START-07-24-00106', 'Christine', 'Mendoza', 'Tomas', '', 'Female', '2007-03-20', 19, '9400634499', 'christine.mendoza7@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Cebu City', 'Bicol Universtiy Polangui Campus', 2, 'Information Systems', 'Merit', '2025'),
('START-07-25-00065', 'Kevin', 'Del Rosario', 'Aquino', '', 'Male', '2008-09-03', 18, '9905235028', 'kevin.del rosario49@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Mandaue City', 'Bulacan State University - Malolos Campus', 1, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2026'),
('START-07-25-00145', 'Paul', 'Reyes', 'Bulanadi', '', 'Male', '2007-05-04', 19, '9972046860', 'paul.reyes88@example.com', 'Region VII (Central Visayas)', 'Bohol', 'Tagbilaran City', 'Cavite State University - Imus Campus', 2, 'Applied Mathematics', 'Merit', '2025'),
('START-07-26-00012', 'Angelo', 'Valmonte', 'Soriano', '', 'Male', '2004-12-07', 22, '9319540545', 'angelo.valmonte5@example.com', 'Region VII (Central Visayas)', 'Cebu', 'Mandaue City', 'Mindanao States University - Iligan Institute of Technology', 4, 'Statistics', 'RA 7687', '2023'),
('START-08-24-00003', 'Miguel', 'Navarro', 'Ramos', '', 'Male', '2006-12-09', 20, '9332679900', 'miguel.navarro69@example.com', 'Region VIII (Eastern Visayas)', 'Samar', 'Catbalogan City', 'Polytechnic University of the Philippines Manila', 2, 'Information Systems', 'Merit', '2025'),
('START-08-24-00037', 'Mary', 'Valmonte', 'Castillo', '', 'Female', '2006-12-26', 20, '9779120359', 'mary.valmonte75@example.com', 'Region VIII (Eastern Visayas)', 'Leyte', 'Ormoc City', 'Polytechnic University of the Philippines Manila', 3, 'Electronics and Communication Engineering', 'RA 7687', '2024'),
('START-08-24-00081', 'Joshua', 'Garcia', 'Santos', 'III', 'Male', '2006-02-28', 20, '9311962175', 'joshua.garcia82@example.com', 'Region VIII (Eastern Visayas)', 'Samar', 'Calbayog City', 'University of Saint Louis-Tuguegarao', 3, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2024'),
('START-08-24-00129', 'Rhea', 'Ramos', 'Rodriguez', '', 'Female', '2005-12-05', 21, '9719103691', 'rhea.ramos22@example.com', 'Region VIII (Eastern Visayas)', 'Leyte', 'Tacloban City', 'Pampanga State University - Main Campus', 4, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2023'),
('START-08-24-00134', 'Sarah', 'Valmonte', 'Garcia', '', 'Female', '2008-12-26', 18, '9841882420', 'sarah.valmonte35@example.com', 'Region VIII (Eastern Visayas)', 'Samar', 'Calbayog City', 'Polytechnic University of the Philippines- Main Campus', 1, 'Computer Science', 'Merit', '2026'),
('START-08-25-00030', 'Carl', 'Lopez', 'Soriano', '', 'Male', '2005-03-06', 21, '9961912427', 'carl.lopez51@example.com', 'Region VIII (Eastern Visayas)', 'Leyte', 'Ormoc City', 'University of the Immaculate Conception', 4, 'Management Information Systems', 'RA 7687', '2023'),
('START-08-26-00028', 'Juan', 'Bulanadi', 'Reyes', '', 'Male', '2004-05-05', 22, '9257657185', 'juan.bulanadi99@example.com', 'Region VIII (Eastern Visayas)', 'Leyte', 'Tacloban City', 'Saint Louis University', 4, 'Industrial Management Engineering – Information Technology', 'Merit', '2023'),
('START-08-26-00055', 'Sofia', 'Soriano', 'Perez', '', 'Female', '2008-04-29', 18, '9886524239', 'sofia.soriano29@example.com', 'Region VIII (Eastern Visayas)', 'Samar', 'Calbayog City', 'Polytechnic University of the Philippines - Taguig Campus', 1, 'Information Technology Systems', 'Merit', '2026'),
('START-08-26-00088', 'Charlene', 'Torres', 'Perez', '', 'Female', '2007-02-17', 19, '9331540965', 'charlene.torres35@example.com', 'Region VIII (Eastern Visayas)', 'Leyte', 'Ormoc City', 'Technological University of the Philippines - Taguig Campus', 1, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2026'),
('START-08-26-00094', 'Miguel', 'Rodriguez', 'Garcia', '', 'Male', '2005-02-22', 21, '9759340617', 'miguel.rodriguez75@example.com', 'Region VIII (Eastern Visayas)', 'Samar', 'Catbalogan City', 'Cagayan State University - Carig Campusa', 3, 'Computer Science', 'JLSS - RA 7687', '2026'),
('START-09-24-00040', 'Rhea', 'Cruz', 'Garcia', '', 'Female', '2004-01-21', 22, '9296898664', 'rhea.cruz45@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Norte', 'Dipolog City', 'Lyceum of the Philippines University - Manila', 4, 'Statistics', 'JLSS - RA 7687', '2025'),
('START-09-24-00101', 'Jerome', 'Dizon', 'Bautista', '', 'Male', '2006-05-15', 20, '9735263885', 'jerome.dizon31@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Norte', 'Dapitan City', 'President Ramon Magsaysay State University - San Marcelino', 3, 'Statistics', 'RA 7687', '2024'),
('START-09-24-00144', 'Ivan', 'Aquino', 'Aquino', 'IV', 'Male', '2006-04-11', 20, '9394573946', 'ivan.aquino64@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Norte', 'Dapitan City', 'Cebu Institutes of Technology - University', 2, 'Electronics and Communication Engineering', 'Merit', '2025'),
('START-09-25-00018', 'Marian', 'Reyes', 'Torres', '', 'Female', '2007-03-19', 19, '9622823997', 'marian.reyes25@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Norte', 'Dipolog City', 'Bulacan State University- Malolos Campus', 1, 'Information Systems', 'RA 7687', '2026'),
('START-09-25-00061', 'Francis', 'Villanueva', 'Chuaunsu', '', 'Male', '2006-09-22', 20, '9312099130', 'francis.villanueva97@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Sur', 'Pagadian City', 'Silliman University', 2, 'Information Technology Systems', 'Merit', '2025'),
('START-09-26-00045', 'Mary', 'Torres', 'Bulanadi', '', 'Female', '2005-05-21', 21, '9140979527', 'mary.torres16@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Sur', 'Zamboanga City', 'Cebu Institute of Technology-University', 4, 'Applied Mathematics', 'Merit', '2023'),
('START-09-26-00089', 'Gabriel', 'Soriano', 'Torres', '', 'Male', '2007-12-24', 19, '9503902510', 'gabriel.soriano87@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Sur', 'Zamboanga City', 'Cagayan State University - Carig Campus', 1, 'Applied Mathematics', 'Merit', '2026'),
('START-09-26-00137', 'Isabella', 'Villanueva', 'Rodriguez', '', 'Female', '2005-04-19', 21, '9473652339', 'isabella.villanueva39@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Sur', 'Zamboanga City', 'Marinduque State University- Main Campus', 4, 'Management Information Systems', 'Merit', '2023'),
('START-09-26-00147', 'Gabriel', 'Bautista', 'Flores', '', 'Male', '2005-06-17', 21, '9171411755', 'gabriel.bautista34@example.com', 'Region IX (Zamboanga Peninsula)', 'Zamboanga del Sur', 'Zamboanga City', 'Technological University of the Philippines - Taguig', 3, 'Statistics', 'Merit', '2024'),
('START-10-24-00112', 'Angelica', 'Del Rosario', 'Del Rosario', '', 'Female', '2007-08-09', 19, '9758063906', 'angelica.del rosario83@example.com', 'Region X (Northern Mindanao)', 'Bukidnon', 'Valencia City', 'Negros Oriental State University', 1, 'Management Information Systems', 'Merit', '2026'),
('START-10-25-00008', 'Grace', 'Rodriguez', 'Gomez', '', 'Female', '2006-01-07', 20, '9592654021', 'grace.rodriguez84@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Cagayan de Oro City', 'Isabela State University - Echague Campus', 3, 'Information Technology Systems', 'RA 7687', '2024'),
('START-10-25-00014', 'Ian', 'Cruz', 'Navarro', 'Jr.', 'Male', '2005-02-25', 21, '9332762337', 'ian.cruz83@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Cagayan de Oro City', 'Ateneo de Manila University', 3, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2024'),
('START-10-25-00019', 'Maria', 'Soriano', 'Mendoza', '', 'Female', '2006-07-12', 20, '9876098127', 'maria.soriano83@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Cagayan de Oro City', 'University of Science and Technology of Southern Philippines - Cagayan de the Oro', 3, 'Management Information Systems', 'RA 7687', '2024'),
('START-10-25-00029', 'Diana', 'Flores', 'Gonzales', '', 'Female', '2003-03-22', 23, '9111916383', 'diana.flores49@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'Cebu Technological University - Tuburan Campus', 5, 'Statistics', 'Merit', '2022'),
('START-10-25-00047', 'Grace', 'Soriano', 'Perez', '', 'Female', '2006-06-14', 20, '9577728801', 'grace.soriano55@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'CENTRAL LUZON STATE UNIVERSITY', 3, 'Management Information Systems', 'Merit', '2024'),
('START-10-25-00063', 'Paul', 'Torres', 'Santos', 'IV', 'Male', '2006-09-21', 20, '9638139887', 'paul.torres46@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Cagayan de Oro City', 'University of Mindanao - Main', 3, 'Electronics and Communication Engineering', 'Merit', '2024'),
('START-10-25-00082', 'Sofia', 'Castillo', 'Cruz', '', 'Female', '2005-12-31', 21, '9672651208', 'sofia.castillo10@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'Batangas State University, The National Engineering University - Balayan Campus', 3, 'Information and Communications Technology', 'Merit', '2024'),
('START-10-25-00092', 'Paolo', 'Cruz', 'Santos', '', 'Male', '2004-05-02', 22, '9839911902', 'paolo.cruz19@example.com', 'Region X (Northern Mindanao)', 'Bukidnon', 'Malaybalay City', 'Mindanao State University - Main', 4, 'Industrial Management Engineering – Information Technology', 'Merit', '2023'),
('START-10-25-00097', 'Kimberly', 'Ramos', 'Soriano', '', 'Female', '2006-09-07', 20, '9206705494', 'kimberly.ramos58@example.com', 'Region X (Northern Mindanao)', 'Bukidnon', 'Malaybalay City', 'Xavier University - Ateneo de Cagayan', 2, 'Information Technology Systems', 'RA 7687', '2025'),
('START-10-25-00102', 'Maria', 'Gonzales', 'Soriano', '', 'Female', '2008-08-05', 18, '9158636610', 'maria.gonzales30@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'Nueva Vizcaya State University - Bambang Campus', 1, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'Merit', '2026'),
('START-10-26-00050', 'Sarah', 'Del Rosario', 'Gomez', '', 'Female', '2007-04-22', 19, '9216813191', 'sarah.del rosario33@example.com', 'Region X (Northern Mindanao)', 'Bukidnon', 'Malaybalay City', 'Technological University of the Philippines - Taguig Campus', 1, 'Statistics', 'Merit', '2026'),
('START-10-26-00054', 'Juan', 'Tomas', 'Lopez', 'Jr.', 'Male', '2007-03-09', 19, '9758960978', 'juan.tomas72@example.com', 'Region X (Northern Mindanao)', 'Bukidnon', 'Valencia City', 'Angeles University Foundation', 1, 'Computer Engineering', 'RA 7687', '2026'),
('START-10-26-00093', 'Ian', 'Flores', 'Perez', '', 'Male', '2007-06-01', 19, '9656063499', 'ian.flores47@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'Ateneo de Naga University', 2, 'Computer Science', 'RA 7687', '2025'),
('START-10-26-00098', 'Christian', 'Valmonte', 'Aquino', '', 'Male', '2006-02-20', 20, '9360957591', 'christian.valmonte40@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'Batangas State University - The National Engineering University Alangilan Campus', 3, 'Information Technology Systems', 'RA 7687', '2024'),
('START-10-26-00103', 'Nicole', 'Castillo', 'Torres', '', 'Female', '2006-06-29', 20, '9495869006', 'nicole.castillo11@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Gingoog City', 'University of Saint Louis-Tuguegarao', 3, 'Information Technology', 'RA 7687', '2024'),
('START-10-26-00119', 'Michael', 'Soriano', 'Torres', '', 'Male', '2004-12-04', 22, '9436015789', 'michael.soriano64@example.com', 'Region X (Northern Mindanao)', 'Misamis Oriental', 'Cagayan de Oro City', 'Cavite State University - Indang Campus', 4, 'Information Technology', 'Merit', '2023'),
('START-11-25-00023', 'Patricia', 'Villanueva', 'Del Rosario', '', 'Female', '2005-03-11', 21, '9517250660', 'patricia.villanueva13@example.com', 'Region XI (Davao Region)', 'Davao del Norte', 'Tagum City', 'Cebu Technological University - and Main', 4, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'Merit', '2023'),
('START-11-26-00004', 'Kevin', 'Gomez', 'Santos', '', 'Male', '2005-08-10', 21, '9534516126', 'kevin.gomez88@example.com', 'Region XI (Davao Region)', 'Davao del Sur', 'Digos City', 'University of Science and Technology of Southern Philippines', 4, 'Computer Engineering', 'RA 7687', '2023'),
('START-11-26-00052', 'Francis', 'Cruz', 'Torres', '', 'Male', '2003-02-04', 23, '9774191994', 'francis.cruz53@example.com', 'Region XI (Davao Region)', 'Davao del Norte', 'Panabo City', 'Batangas State University - The National Engineering University Alangilan Campus', 5, 'Information Systems', 'RA 7687', '2022'),
('START-12-24-00120', 'Ivan', 'Chuaunsu', 'Gomez', '', 'Male', '2007-10-31', 19, '9547895640', 'ivan.chuaunsu43@example.com', 'Region XII (SOCCSKSARGEN)', 'Cotabato', 'Makilala', 'Marinduque State University- Main Campus', 2, 'Management Information Systems', 'RA 7687', '2025'),
('START-12-25-00080', 'Angelica', 'Torres', 'Flores', '', 'Female', '2005-06-15', 21, '9494665358', 'angelica.torres10@example.com', 'Region XII (SOCCSKSARGEN)', 'Cotabato', 'Kidapawan City', 'Xavier University- Ateneo de Cagayan', 4, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'Merit', '2023'),
('START-12-25-00139', 'Vincent', 'Cruz', 'Reyes', '', 'Male', '2005-05-03', 21, '9874420064', 'vincent.cruz78@example.com', 'Region XII (SOCCSKSARGEN)', 'South Cotabato', 'General Santos City', 'Bicol University- West Campus', 3, 'Electronics and Communication Engineering', 'RA 7687', '2024'),
('START-12-26-00046', 'John', 'Ocampo', 'Del Rosario', 'IV', 'Male', '2005-03-07', 21, '9568896920', 'john.ocampo83@example.com', 'Region XII (SOCCSKSARGEN)', 'Cotabato', 'Kidapawan City', 'Southern Luzon State University - Main', 4, 'Information Systems', 'Merit', '2023'),
('START-12-26-00125', 'Andrea', 'Dizon', 'Ocampo', '', 'Female', '2004-06-05', 22, '9610410412', 'andrea.dizon57@example.com', 'Region XII (SOCCSKSARGEN)', 'South Cotabato', 'Koronadal City', 'Pamantasan ng Lungsod ng Maynila', 4, 'Computer Science', 'RA 7687', '2023'),
('START-13-24-00041', 'Ryan', 'Reyes', 'Ramos', '', 'Male', '2008-07-18', 18, '9508302083', 'ryan.reyes68@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Manila', 'Bulacan State University - Malolos Campus (Main Campus)', 1, 'Computer Engineering', 'RA 7687', '2026'),
('START-13-24-00062', 'Camille', 'Lopez', 'Reyes', '', 'Female', '2007-11-17', 19, '9340092169', 'camille.lopez36@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Taguig City', 'Pamantasan ng Lungsod ng Maynila', 1, 'Information and Communications Technology', 'Merit', '2026'),
('START-13-24-00132', 'Samantha', 'Lopez', 'Castillo', '', 'Female', '2006-09-09', 20, '9136153154', 'samantha.lopez61@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Makati City', 'Southern Luzon State University - Main Campus', 3, 'Information and Communications Technology', 'JLSS - RA 7687', '2026'),
('START-13-25-00053', 'Carlo', 'Tomas', 'Castillo', 'IV', 'Male', '2004-05-05', 22, '9646008676', 'carlo.tomas60@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Manila', 'Cebu Institute of Technology - University', 5, 'Information and Communications Technology', 'JLSS - RA 7687', '2024'),
('START-13-25-00099', 'Nicole', 'Reyes', 'Ocampo', '', 'Female', '2008-05-18', 18, '9209077368', 'nicole.reyes52@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Taguig City', 'Negros Oriental State University - Main Campus', 1, 'Electronics and Communication Engineering', 'Merit', '2026'),
('START-13-26-00013', 'Isabella', 'Reyes', 'Santos', '', 'Female', '2003-11-22', 23, '9749031617', 'isabella.reyes82@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Makati City', 'Marinduque State University - Boac Campus', 5, 'Electronics and Communication Engineering', 'RA 7687', '2022'),
('START-13-26-00033', 'Paul', 'Villanueva', 'Bulanadi', '', 'Male', '2004-09-06', 22, '9473248142', 'paul.villanueva74@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Makati City', 'Leyte Normal University - Main Campus', 4, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2023'),
('START-13-26-00049', 'Andrea', 'Lopez', 'Torres', '', 'Female', '2006-09-26', 20, '9536887836', 'andrea.lopez97@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Manila', 'University of Batangas - Batangas City Campus', 3, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2024'),
('START-13-26-00059', 'Francis', 'Ocampo', 'Del Rosario', '', 'Male', '2005-11-16', 21, '9755628354', 'francis.ocampo22@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Taguig City', 'Mindanao State University - Iligan Institute of Technology', 4, 'Computer Science', 'Merit', '2023'),
('START-13-26-00150', 'Sarah', 'Castillo', 'Mendoza', '', 'Female', '2005-11-20', 21, '9752482776', 'sarah.castillo23@example.com', 'NCR (National Capital Region)', 'Metro Manila', 'Quezon City', 'Batangas State University - Alangilan', 4, 'Industrial Management Engineering – Information Technology', 'Merit', '2023'),
('START-14-24-00006', 'Grace', 'Ramos', 'Flores', '', 'Female', '2005-03-13', 21, '9462448645', 'grace.ramos49@example.com', 'CAR (Cordillera Administrative Region)', 'Benguet', 'Baguio City', 'Technological University of the Philippines - Cavite', 3, 'Electronics and Communication Engineering', 'RA 7687', '2024'),
('START-14-24-00034', 'Mary', 'Reyes', 'Cruz', '', 'Female', '2007-03-31', 19, '9652660737', 'mary.reyes37@example.com', 'CAR (Cordillera Administrative Region)', 'Mountain Province', 'Sagada', 'Saint Mary\'s University - Bayombong', 2, 'Information Technology', 'RA 7687', '2025'),
('START-14-24-00056', 'Andrea', 'Tomas', 'Bulanadi', '', 'Female', '2005-12-16', 21, '9494039867', 'andrea.tomas22@example.com', 'CAR (Cordillera Administrative Region)', 'Mountain Province', 'Sagada', 'Bulacan State University - Malolos Campus (Main Campus)', 3, 'Electronics and Communication Engineering', 'JLSS - Merit', '2026'),
('START-14-25-00007', 'Mark', 'Castillo', 'Castillo', '', 'Male', '2005-02-16', 21, '9600492449', 'mark.castillo27@example.com', 'CAR (Cordillera Administrative Region)', 'Benguet', 'Baguio City', 'De La Salle University Dasmariñas', 3, 'Electronics and Communication Engineering', 'RA 7687', '2024'),
('START-14-25-00024', 'Grace', 'Castillo', 'Reyes', '', 'Female', '2008-10-11', 18, '9678511506', 'grace.castillo66@example.com', 'CAR (Cordillera Administrative Region)', 'Mountain Province', 'Sagada', 'Polytechnic University of the Philippines - Santa Rosa Campus', 1, 'Statistics', 'RA 7687', '2026'),
('START-14-25-00090', 'Vincent', 'Torres', 'Bautista', '', 'Male', '2007-08-20', 19, '9884875178', 'vincent.torres96@example.com', 'CAR (Cordillera Administrative Region)', 'Mountain Province', 'Bontoc', 'University of Santo Tomas - Manila', 1, 'Information and Communications Technology', 'Merit', '2026'),
('START-14-25-00117', 'John', 'Del Rosario', 'Villanueva', '', 'Male', '2005-03-05', 21, '9263912020', 'john.del rosario43@example.com', 'CAR (Cordillera Administrative Region)', 'Benguet', 'La Trinidad', 'Asia Pacific College', 4, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2023'),
('START-14-26-00066', 'Rhea', 'Mendoza', 'Villanueva', '', 'Female', '2007-01-22', 19, '9212556823', 'rhea.mendoza58@example.com', 'CAR (Cordillera Administrative Region)', 'Benguet', 'Baguio City', 'University of the Philippines - Visayas', 1, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2026'),
('START-14-26-00100', 'Jasmine', 'Aquino', 'Villanueva', '', 'Female', '2007-03-08', 19, '9853551837', 'jasmine.aquino10@example.com', 'CAR (Cordillera Administrative Region)', 'Benguet', 'La Trinidad', 'De La Salle University - Dasmariñas', 2, 'Computer Engineering', 'RA 7687', '2025'),
('START-15-24-00016', 'Samantha', 'Ocampo', 'Aquino', '', 'Female', '2003-11-10', 23, '9198040482', 'samantha.ocampo36@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Maguindanao', 'Cotabato City', 'University of the Philippines - Visayas', 5, 'Information Technology Systems', 'Merit', '2022'),
('START-15-24-00086', 'Michelle', 'Torres', 'Tomas', '', 'Female', '2004-07-11', 22, '9222916120', 'michelle.torres12@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Maguindanao', 'Datu Odin Sinsuat', 'University of the Philippines Los Baños', 4, 'Electronics and Communication Engineering', 'Merit', '2023'),
('START-15-24-00095', 'Jerome', 'Del Rosario', 'Dizon', '', 'Male', '2008-08-06', 18, '9510482749', 'jerome.del rosario25@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Lanao del Sur', 'Marawi City', 'University of Saint Louis-Tuguegarao', 1, 'Information Technology Systems', 'RA 7687', '2026'),
('START-15-24-00116', 'John', 'Torres', 'Ramos', '', 'Male', '2004-10-09', 22, '9575958104', 'john.torres46@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Maguindanao', 'Cotabato City', 'Cebu Technological University', 4, 'Applied Mathematics', 'RA 7687', '2023'),
('START-15-24-00126', 'Marian', 'Castillo', 'Reyes', '', 'Female', '2004-06-19', 22, '9181686400', 'marian.castillo78@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Lanao del Sur', 'Marawi City', 'Polytechnic University of the Philippines - Mabini Campus', 4, 'Applied Mathematics', 'RA 7687', '2023'),
('START-15-25-00009', 'Vincent', 'Bulanadi', 'Torres', '', 'Male', '2008-05-27', 18, '9532977013', 'vincent.bulanadi52@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Maguindanao', 'Datu Odin Sinsuat', 'Batangas State University, The National Engineering University – Alangilan', 1, 'Industrial Management Engineering – Information Technology', 'Merit', '2026'),
('START-15-25-00128', 'Maria', 'Gomez', 'Torres', '', 'Female', '2008-01-30', 18, '9949567781', 'maria.gomez53@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Maguindanao', 'Datu Odin Sinsuat', 'University of Saint Louis-Tuguegarao', 1, 'Information Systems', 'RA 7687', '2026'),
('START-15-26-00021', 'David', 'Santos', 'Gonzales', '', 'Male', '2007-05-19', 19, '9330318371', 'david.santos88@example.com', 'BARMM (Bangsamoro Autonomous Region in Muslim Mindanao)', 'Lanao del Sur', 'Marawi City', 'Universidad de Dagupan', 1, 'Statistics', 'Merit', '2026'),
('START-16-25-00001', 'Gabriel', 'Chuaunsu', 'Villanueva', '', 'Male', '2007-06-18', 19, '9307539937', 'gabriel.chuaunsu21@example.com', 'Region XIII (Caraga)', 'Agusan del Norte', 'Butuan City', 'Leyte Normal University - Main Campus', 2, 'Electronics and Communication Engineering', 'Merit', '2025'),
('START-16-25-00060', 'Ian', 'Garcia', 'Castillo', '', 'Male', '2006-02-04', 20, '9753743049', 'ian.garcia81@example.com', 'Region XIII (Caraga)', 'Agusan del Norte', 'Cabadbaran City', 'Ateneo De Davao University', 3, 'Information Systems', 'Merit', '2024'),
('START-16-25-00096', 'Ian', 'Valmonte', 'Chuaunsu', '', 'Male', '2004-01-30', 22, '9302521629', 'ian.valmonte65@example.com', 'Region XIII (Caraga)', 'Surigao del Norte', 'Surigao City', 'CEBU INSTITUTE OF TECHNOLOGY - UNIVERSITY', 4, 'Information Systems', 'Merit', '2023'),
('START-16-25-00110', 'Juan', 'Mendoza', 'Garcia', '', 'Male', '2007-01-02', 19, '9626718771', 'juan.mendoza46@example.com', 'Region XIII (Caraga)', 'Surigao del Norte', 'Surigao City', 'Palawan State University - Main Campus', 2, 'Information Technology', 'RA 7687', '2025'),
('START-16-26-00031', 'Paul', 'Garcia', 'Navarro', '', 'Male', '2006-12-18', 20, '9821928605', 'paul.garcia40@example.com', 'Region XIII (Caraga)', 'Surigao del Norte', 'Surigao City', 'RIZAL TECHNOLOGICAL UNIVERSITY - BONI CAMPUS', 3, 'Information Technology', 'RA 7687', '2024'),
('START-16-26-00032', 'Paolo', 'Reyes', 'Gonzales', '', 'Male', '2007-03-30', 19, '9914343569', 'paolo.reyes82@example.com', 'Region XIII (Caraga)', 'Agusan del Norte', 'Cabadbaran City', 'Bulacan State University- Malolos Campus', 1, 'Information Systems', 'RA 7687', '2026'),
('START-16-26-00057', 'Charlene', 'Bulanadi', 'Perez', '', 'Female', '2008-02-19', 18, '9448683925', 'charlene.bulanadi26@example.com', 'Region XIII (Caraga)', 'Surigao del Norte', 'Surigao City', 'President Ramon Magsaysay State University', 1, 'Computer Science', 'RA 7687', '2026'),
('START-16-26-00079', 'Charlene', 'Dizon', 'Soriano', '', 'Female', '2003-09-13', 23, '9951905919', 'charlene.dizon32@example.com', 'Region XIII (Caraga)', 'Surigao del Norte', 'Dapa', 'RIZAL TECHNOLOGICAL UNIVERSITY - BONI CAMPUS', 5, 'Management Information Systems', 'Merit', '2022'),
('START-16-26-00124', 'Ryan', 'Villanueva', 'Gonzales', '', 'Male', '2005-10-08', 21, '9814022794', 'ryan.villanueva43@example.com', 'Region XIII (Caraga)', 'Agusan del Norte', 'Butuan City', 'Xavier University- Ateneo de Cagayan', 4, 'Applied Mathematics', 'Merit', '2023'),
('START-17-24-00035', 'Jasmine', 'Bautista', 'Flores', '', 'Female', '2005-11-01', 21, '9901972270', 'jasmine.bautista19@example.com', 'MIMAROPA Region', 'Oriental Mindoro', 'Calapan City', 'UNIVERSITY OF THE PHILIPPINES - CEBU', 3, 'Industrial Management Engineering – Information Technology', 'RA 7687', '2024'),
('START-17-25-00074', 'Rhea', 'Ramos', 'Del Rosario', '', 'Female', '2005-10-14', 21, '9103354719', 'rhea.ramos62@example.com', 'MIMAROPA Region', 'Palawan', 'El Nido', 'Technological University of the Philippines - Cavite', 3, 'Information Systems', 'Merit', '2024'),
('START-17-26-00051', 'Angelo', 'Santos', 'Dizon', '', 'Male', '2008-05-27', 18, '9872842879', 'angelo.santos1@example.com', 'MIMAROPA Region', 'Oriental Mindoro', 'Baco', 'Bicol Universtiy Polangui Campus', 1, 'Information Technology', 'RA 7687', '2026'),
('START-17-26-00109', 'Francis', 'Gonzales', 'Villanueva', '', 'Male', '2007-10-07', 19, '9859212724', 'francis.gonzales55@example.com', 'MIMAROPA Region', 'Oriental Mindoro', 'Baco', 'University of Saint Louis Tuguegarao - Main Campus', 1, 'Industrial Management Engineering – Information Technology', 'Merit', '2026'),
('START-18-24-00133', 'Diana', 'Del Rosario', 'Chuaunsu', '', 'Female', '2005-09-01', 21, '9632711427', 'diana.del rosario99@example.com', 'NIR (Negros Island Region)', 'Negros Oriental', 'Bais City', 'Polytechnic University of the Philippines', 4, 'Information and Communications Technology', 'JLSS - Merit', '2025'),
('START-18-25-00011', 'Samantha', 'Ramos', 'Del Rosario', '', 'Female', '2005-06-03', 21, '9358473717', 'samantha.ramos56@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Bacolod City', 'University of San Carlos - Talamban Campus', 3, 'Electronics and Communication Engineering', 'Merit', '2024'),
('START-18-25-00085', 'Paolo', 'Rodriguez', 'Rodriguez', '', 'Male', '2006-03-02', 20, '9764272450', 'paolo.rodriguez99@example.com', 'NIR (Negros Island Region)', 'Negros Oriental', 'Bais City', 'West Visayas State University - Main Campus', 3, 'Information and Communications Technology', 'Merit', '2024'),
('START-18-25-00108', 'Carlo', 'Reyes', 'Santos', '', 'Male', '2007-08-25', 19, '9996348066', 'carlo.reyes95@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Silay City', 'Manuel S. Enverga University Foundation - Lucena City', 1, 'Computer Engineering', 'RA 7687', '2026'),
('START-18-25-00130', 'Patricia', 'Torres', 'Perez', '', 'Female', '2006-01-26', 20, '9610706420', 'patricia.torres16@example.com', 'NIR (Negros Island Region)', 'Negros Oriental', 'Bais City', 'Eastern Visayas State University', 3, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2024'),
('START-18-25-00135', 'Michael', 'Bulanadi', 'Lopez', '', 'Male', '2005-04-11', 21, '9567827485', 'michael.bulanadi82@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Bacolod City', 'Main campus Paranas', 4, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'RA 7687', '2023'),
('START-18-25-00141', 'Joshua', 'Rodriguez', 'Del Rosario', 'IV', 'Male', '2008-10-12', 18, '9340841790', 'joshua.rodriguez64@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Silay City', 'University of the Philippines - Los Baños', 1, 'Computer Science', 'RA 7687', '2026'),
('START-18-26-00078', 'Marian', 'Del Rosario', 'Rodriguez', '', 'Female', '2005-03-16', 21, '9335152846', 'marian.del rosario57@example.com', 'NIR (Negros Island Region)', 'Negros Oriental', 'Bais City', 'Negros Oriental State University', 3, 'Technology and Livelihood Education With Specialization in Information and Communication Technology', 'JLSS - Merit', '2026'),
('START-18-26-00111', 'Jose', 'Ocampo', 'Bautista', '', 'Male', '2007-05-09', 19, '9545466072', 'jose.ocampo35@example.com', 'NIR (Negros Island Region)', 'Negros Oriental', 'Bais City', 'Saint Mary\'s University - Bayombong', 1, 'Computer Engineering', 'RA 7687', '2026'),
('START-18-26-00113', 'Kimberly', 'Ramos', 'Gonzales', '', 'Female', '2008-05-18', 18, '9282734929', 'kimberly.ramos13@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Silay City', 'Bulacan State University - Main Campus', 1, 'Information Technology Systems', 'RA 7687', '2026'),
('START-18-26-00123', 'Patricia', 'Santos', 'Ocampo', '', 'Female', '2006-06-23', 20, '9148826874', 'patricia.santos37@example.com', 'NIR (Negros Island Region)', 'Negros Occidental', 'Bacolod City', 'Visayas State University - Isabel Campus', 2, 'Information Technology', 'Merit', '2025');

-- --------------------------------------------------------

--
-- Table structure for table `membership_record`
--

CREATE TABLE `membership_record` (
  `Record_ID` int(11) NOT NULL,
  `START_ID` varchar(20) NOT NULL,
  `Committee_ID` int(11) NOT NULL,
  `Role_ID` int(11) NOT NULL,
  `Academic_Year` varchar(9) NOT NULL,
  `Status` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `membership_record`
--

INSERT INTO `membership_record` (`Record_ID`, `START_ID`, `Committee_ID`, `Role_ID`, `Academic_Year`, `Status`) VALUES
(2, 'START-06-24-00002', 12, 31, '2026-2027', 'accepted'),
(3, 'START-08-24-00003', 12, 31, '2026-2027', 'accepted'),
(4, 'START-11-26-00004', 12, 31, '2026-2027', 'accepted'),
(5, 'START-05-24-00005', 12, 31, '2026-2027', 'accepted'),
(6, 'START-14-24-00006', 12, 31, '2026-2027', 'accepted'),
(7, 'START-14-25-00007', 1, 1, '2026-2027', 'accepted'),
(8, 'START-10-25-00008', 12, 31, '2026-2027', 'accepted'),
(9, 'START-15-25-00009', 1, 31, '2026-2027', 'accepted'),
(10, 'START-06-24-00010', 1, 2, '2026-2027', 'accepted'),
(11, 'START-18-25-00011', 16, 3, '2026-2027', 'accepted'),
(12, 'START-07-26-00012', 13, 31, '2026-2027', 'accepted'),
(13, 'START-13-26-00013', 12, 31, '2026-2027', 'accepted'),
(14, 'START-10-25-00014', 19, 4, '2026-2027', 'accepted'),
(15, 'START-05-24-00015', 18, 5, '2026-2027', 'accepted'),
(16, 'START-15-24-00016', 17, 6, '2026-2027', 'accepted'),
(17, 'START-04-24-00017', 12, 31, '2026-2027', 'accepted'),
(18, 'START-04-24-00017', 12, 31, '2026-2027', 'accepted'),
(19, 'START-10-25-00019', 20, 7, '2026-2027', 'accepted'),
(20, 'START-02-24-00020', 12, 31, '2026-2027', 'accepted'),
(21, 'START-15-26-00021', 1, 8, '2026-2027', 'accepted'),
(22, 'START-05-24-00022', 1, 9, '2026-2027', 'accepted'),
(23, 'START-11-25-00023', 16, 10, '2026-2027', 'accepted'),
(24, 'START-14-25-00024', 16, 11, '2026-2027', 'accepted'),
(25, 'START-05-26-00025', 19, 12, '2026-2027', 'accepted'),
(26, 'START-07-24-00026', 18, 13, '2026-2027', 'accepted'),
(27, 'START-05-25-00027', 18, 14, '2026-2027', 'accepted'),
(28, 'START-08-26-00028', 17, 15, '2026-2027', 'accepted'),
(29, 'START-10-25-00029', 17, 16, '2026-2027', 'accepted'),
(30, 'START-08-25-00030', 20, 17, '2026-2027', 'accepted'),
(31, 'START-16-26-00031', 20, 18, '2026-2027', 'accepted'),
(32, 'START-16-26-00032', 21, 19, '2026-2027', 'accepted'),
(33, 'START-13-26-00033', 21, 20, '2026-2027', 'accepted'),
(34, 'START-14-24-00034', 2, 21, '2026-2027', 'accepted'),
(35, 'START-17-24-00035', 12, 31, '2026-2027', 'accepted'),
(36, 'START-07-24-00036', 2, 21, '2026-2027', 'accepted'),
(37, 'START-08-24-00037', 2, 21, '2026-2027', 'accepted'),
(38, 'START-04-25-00038', 3, 22, '2026-2027', 'accepted'),
(39, 'START-06-24-00039', 3, 22, '2026-2027', 'accepted'),
(40, 'START-09-24-00040', 3, 22, '2026-2027', 'accepted'),
(41, 'START-13-24-00041', 4, 23, '2026-2027', 'accepted'),
(42, 'START-04-24-00042', 4, 23, '2026-2027', 'accepted'),
(43, 'START-04-24-00043', 4, 23, '2026-2027', 'accepted'),
(44, 'START-07-24-00044', 5, 24, '2026-2027', 'accepted'),
(45, 'START-09-26-00045', 5, 24, '2026-2027', 'accepted'),
(46, 'START-12-26-00046', 12, 31, '2026-2027', 'accepted'),
(47, 'START-10-25-00047', 5, 24, '2026-2027', 'accepted'),
(48, 'START-07-24-00048', 6, 25, '2026-2027', 'accepted'),
(49, 'START-13-26-00049', 6, 25, '2026-2027', 'accepted'),
(50, 'START-10-26-00050', 7, 25, '2026-2027', 'accepted'),
(51, 'START-17-26-00051', 7, 26, '2026-2027', 'accepted'),
(52, 'START-11-26-00052', 7, 26, '2026-2027', 'accepted'),
(53, 'START-13-25-00053', 7, 26, '2026-2027', 'accepted'),
(54, 'START-10-26-00054', 8, 27, '2026-2027', 'accepted'),
(55, 'START-08-26-00055', 8, 27, '2026-2027', 'accepted'),
(56, 'START-14-24-00056', 8, 27, '2026-2027', 'accepted'),
(57, 'START-16-26-00057', 9, 28, '2026-2027', 'accepted'),
(58, 'START-02-25-00058', 9, 28, '2026-2027', 'accepted'),
(59, 'START-13-26-00059', 9, 28, '2026-2027', 'accepted'),
(60, 'START-16-25-00060', 10, 29, '2026-2027', 'accepted'),
(61, 'START-09-25-00061', 10, 29, '2026-2027', 'accepted'),
(62, 'START-13-24-00062', 10, 29, '2026-2027', 'accepted'),
(63, 'START-10-25-00063', 11, 30, '2026-2027', 'accepted'),
(64, 'START-06-24-00064', 11, 30, '2026-2027', 'accepted'),
(65, 'START-07-25-00065', 11, 30, '2026-2027', 'accepted'),
(66, 'START-14-26-00066', 13, 32, '2026-2027', 'accepted'),
(67, 'START-04-26-00067', 13, 32, '2026-2027', 'accepted'),
(68, 'START-07-24-00068', 13, 32, '2026-2027', 'accepted'),
(69, 'START-01-25-00069', 12, 31, '2026-2027', 'accepted'),
(70, 'START-07-24-00070', 14, 33, '2026-2027', 'accepted'),
(71, 'START-03-25-00071', 12, 31, '2026-2027', 'accepted'),
(72, 'START-03-24-00072', 14, 33, '2026-2027', 'accepted'),
(73, 'START-01-26-00073', 14, 33, '2026-2027', 'accepted'),
(74, 'START-17-25-00074', 15, 34, '2026-2027', 'accepted'),
(75, 'START-02-24-00075', 15, 34, '2026-2027', 'accepted'),
(76, 'START-06-25-00076', 15, 34, '2026-2027', 'accepted'),
(77, 'START-03-25-00077', 15, 34, '2026-2027', 'accepted'),
(78, 'START-18-26-00078', 15, 34, '2026-2027', 'accepted'),
(79, 'START-16-26-00079', 15, 34, '2026-2027', 'accepted'),
(80, 'START-12-25-00080', 15, 34, '2026-2027', 'accepted'),
(81, 'START-08-24-00081', 15, 34, '2026-2027', 'accepted'),
(82, 'START-10-25-00082', 15, 34, '2026-2027', 'accepted'),
(83, 'START-05-25-00083', 15, 34, '2026-2027', 'accepted'),
(84, 'START-02-25-00084', 15, 34, '2026-2027', 'pending'),
(85, 'START-18-25-00085', 15, 34, '2026-2027', 'accepted'),
(86, 'START-15-24-00086', 15, 34, '2026-2027', 'accepted'),
(87, 'START-02-24-00087', 15, 34, '2026-2027', 'accepted'),
(88, 'START-08-26-00088', 15, 34, '2026-2027', 'accepted'),
(89, 'START-09-26-00089', 15, 34, '2026-2027', 'accepted'),
(90, 'START-14-25-00090', 15, 34, '2026-2027', 'accepted'),
(91, 'START-05-25-00091', 15, 34, '2026-2027', 'rejected'),
(92, 'START-10-25-00092', 15, 34, '2026-2027', 'accepted'),
(93, 'START-10-26-00093', 15, 34, '2026-2027', 'accepted'),
(94, 'START-08-26-00094', 15, 34, '2026-2027', 'accepted'),
(95, 'START-15-24-00095', 15, 34, '2026-2027', 'accepted'),
(96, 'START-16-25-00096', 15, 34, '2026-2027', 'accepted'),
(97, 'START-10-25-00097', 15, 34, '2026-2027', 'accepted'),
(98, 'START-10-26-00098', 15, 34, '2026-2027', 'accepted'),
(99, 'START-13-25-00099', 15, 34, '2026-2027', 'pending'),
(100, 'START-14-26-00100', 15, 34, '2026-2027', 'accepted'),
(101, 'START-09-24-00101', 15, 34, '2026-2027', 'accepted'),
(102, 'START-10-25-00102', 15, 34, '2026-2027', 'accepted'),
(103, 'START-10-26-00103', 15, 34, '2026-2027', 'accepted'),
(104, 'START-02-25-00104', 15, 34, '2026-2027', 'accepted'),
(105, 'START-04-24-00105', 15, 34, '2026-2027', 'accepted'),
(106, 'START-07-24-00106', 15, 34, '2026-2027', 'accepted'),
(107, 'START-01-26-00107', 15, 34, '2026-2027', 'pending'),
(108, 'START-18-25-00108', 15, 34, '2026-2027', 'accepted'),
(109, 'START-17-26-00109', 15, 34, '2026-2027', 'accepted'),
(110, 'START-16-25-00110', 15, 34, '2026-2027', 'accepted'),
(111, 'START-18-26-00111', 15, 34, '2026-2027', 'accepted'),
(112, 'START-10-24-00112', 15, 34, '2026-2027', 'accepted'),
(113, 'START-18-26-00113', 15, 34, '2026-2027', 'accepted'),
(114, 'START-06-26-00114', 15, 34, '2026-2027', 'rejected'),
(115, 'START-03-26-00115', 15, 34, '2026-2027', 'accepted'),
(116, 'START-15-24-00116', 15, 34, '2026-2027', 'accepted'),
(117, 'START-14-25-00117', 15, 34, '2026-2027', 'accepted'),
(118, 'START-06-26-00118', 15, 34, '2026-2027', 'accepted'),
(119, 'START-10-26-00119', 15, 34, '2026-2027', 'accepted'),
(120, 'START-12-24-00120', 15, 34, '2026-2027', 'accepted'),
(121, 'START-02-25-00121', 15, 34, '2026-2027', 'pending'),
(122, 'START-02-24-00122', 15, 34, '2026-2027', 'accepted'),
(123, 'START-18-26-00123', 15, 34, '2026-2027', 'accepted'),
(124, 'START-16-26-00124', 15, 34, '2026-2027', 'accepted'),
(125, 'START-12-26-00125', 15, 34, '2026-2027', 'accepted'),
(126, 'START-15-24-00126', 15, 34, '2026-2027', 'accepted'),
(127, 'START-05-25-00127', 15, 34, '2026-2027', 'accepted'),
(128, 'START-15-25-00128', 15, 34, '2026-2027', 'pending'),
(129, 'START-08-24-00129', 15, 34, '2026-2027', 'accepted'),
(130, 'START-18-25-00130', 15, 34, '2026-2027', 'accepted'),
(131, 'START-06-25-00131', 15, 34, '2026-2027', 'accepted'),
(132, 'START-13-24-00132', 15, 34, '2026-2027', 'accepted'),
(133, 'START-18-24-00133', 15, 34, '2026-2027', 'accepted'),
(134, 'START-08-24-00134', 15, 34, '2026-2027', 'rejected'),
(135, 'START-18-25-00135', 15, 34, '2026-2027', 'accepted'),
(136, 'START-03-26-00136', 15, 34, '2026-2027', 'accepted'),
(137, 'START-09-26-00137', 15, 34, '2026-2027', 'accepted'),
(138, 'START-05-24-00138', 15, 34, '2026-2027', 'accepted'),
(139, 'START-12-25-00139', 15, 34, '2026-2027', 'accepted'),
(140, 'START-01-25-00140', 15, 34, '2026-2027', 'pending'),
(141, 'START-18-25-00141', 15, 34, '2026-2027', 'accepted'),
(142, 'START-04-24-00142', 15, 34, '2026-2027', 'accepted'),
(143, 'START-04-24-00143', 15, 34, '2026-2027', 'accepted'),
(144, 'START-09-24-00144', 15, 34, '2026-2027', 'accepted'),
(145, 'START-07-25-00145', 15, 34, '2026-2027', 'accepted'),
(146, 'START-05-24-00146', 15, 34, '2026-2027', 'pending'),
(147, 'START-09-26-00147', 15, 34, '2026-2027', 'accepted'),
(148, 'START-04-26-00148', 15, 34, '2026-2027', 'accepted'),
(149, 'START-02-26-00149', 15, 34, '2026-2027', 'accepted'),
(150, 'START-13-26-00150', 15, 34, '2026-2027', 'rejected'),
(151, 'START-02-26-00151', 15, 34, '2026-2027', 'pending'),
(152, 'START-01-25-00152', 15, 34, '2026-2027', 'pending'),
(153, 'START-16-25-00001', 12, 31, '2026-2027', 'pending');

--
-- Triggers `membership_record`
--
DELIMITER $$
CREATE TRIGGER `trg_membership_after_delete` AFTER DELETE ON `membership_record` FOR EACH ROW BEGIN

    INSERT INTO membership_record_audit (
        Record_ID,
        START_ID,
        Committee_ID,
        Role_ID,
        Academic_Year,
        Action_Type,
        Old_Status,
        New_Status,
        Changed_By
    )

    VALUES (
        OLD.Record_ID,
        OLD.START_ID,
        OLD.Committee_ID,
        OLD.Role_ID,
        OLD.Academic_Year,
        'DELETE',
        OLD.Status,
        NULL,
        USER()
    );

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_membership_after_insert` AFTER INSERT ON `membership_record` FOR EACH ROW BEGIN

    INSERT INTO membership_record_audit (
        Record_ID,
        START_ID,
        Committee_ID,
        Role_ID,
        Academic_Year,
        Action_Type,
        Old_Status,
        New_Status,
        Changed_By
    )

    VALUES (
        NEW.Record_ID,
        NEW.START_ID,
        NEW.Committee_ID,
        NEW.Role_ID,
        NEW.Academic_Year,
        'INSERT',
        NULL,
        NEW.Status,
        USER()
    );

END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_membership_after_update` AFTER UPDATE ON `membership_record` FOR EACH ROW BEGIN

    IF NOT (OLD.Status <=> NEW.Status) THEN

        INSERT INTO membership_record_audit (
            Record_ID,
            START_ID,
            Committee_ID,
            Role_ID,
            Academic_Year,
            Action_Type,
            Old_Status,
            New_Status,
            Changed_By
        )

        VALUES (
            NEW.Record_ID,
            NEW.START_ID,
            NEW.Committee_ID,
            NEW.Role_ID,
            NEW.Academic_Year,
            'STATUS_UPDATE',
            OLD.Status,
            NEW.Status,
            USER()
        );

    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `membership_record_audit`
--

CREATE TABLE `membership_record_audit` (
  `Audit_ID` bigint(20) UNSIGNED NOT NULL,
  `Record_ID` int(11) NOT NULL,
  `START_ID` varchar(20) NOT NULL,
  `Committee_ID` int(11) NOT NULL,
  `Role_ID` int(11) NOT NULL,
  `Academic_Year` varchar(9) NOT NULL,
  `Action_Type` varchar(20) NOT NULL,
  `Old_Status` varchar(20) DEFAULT NULL,
  `New_Status` varchar(20) DEFAULT NULL,
  `Changed_By` varchar(288) NOT NULL,
  `Changed_At` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `membership_record_audit`
--

INSERT INTO `membership_record_audit` (`Audit_ID`, `Record_ID`, `START_ID`, `Committee_ID`, `Role_ID`, `Academic_Year`, `Action_Type`, `Old_Status`, `New_Status`, `Changed_By`, `Changed_At`) VALUES
(1, 153, 'START-16-25-00001', 12, 31, '2026-2027', 'INSERT', NULL, 'pending', 'root@localhost', '2026-11-08 23:44:18'),
(2, 1, 'START-16-25-00001', 12, 31, '2026-2027', 'DELETE', 'accepted', NULL, 'root@localhost', '2026-11-08 23:45:59');

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role` (
  `Role_Id` int(11) NOT NULL,
  `Role_Title` varchar(100) DEFAULT NULL,
  `Role_Level` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`Role_Id`, `Role_Title`, `Role_Level`) VALUES
(1, 'Chief Executive Officer', 'Chief'),
(2, 'Chief Operations Officer', 'Chief'),
(3, 'Chief Technology Officer', 'Chief'),
(4, 'Chief Finance Officer', 'Chief'),
(5, 'Chief Marketing Officer', 'Chief'),
(6, 'Chief Comminications Officers', 'Chief'),
(7, 'Chief Community Development Officer', 'Chief'),
(8, 'Chief Events Officer', 'Cheif'),
(9, 'Deputy Chief Operations Officer for Administrative Affairs', 'Deputy Chief'),
(10, 'Deputy Chief Technology Officer for Tech Education', 'Deputy Chief'),
(11, 'Deputy Chief Technology Officer for Product Development', 'Deputy Chief'),
(12, 'Deputy Chief Finance Officer for Resource Management & Development', 'Deputy Chief'),
(13, 'Deputy Chief Marketing Officer for Strategic Promotions', 'Deputy Chief'),
(14, 'Deputy Chief Marketing Officer for Creative Contents', 'Deputy Chief'),
(15, 'Deputy Chief Communications Officer for Sponsorships and Media Relations', 'Deputy Chief'),
(16, 'Deputy Chief Communications Officer for Partnerships', 'Deputy Chief'),
(17, 'Deputy Chief Community Development Officer for Development', 'Deputy Chief'),
(18, 'Deputy Chief Community Development Officer for Community', 'Deputy Chief'),
(19, 'Deputy Chief Events Officer for Logistics', 'Deputy Chief'),
(20, 'Deputy Chief Events Officer for Programs', 'Deputy Chief'),
(21, 'Tech Education Committee', 'Committee Member'),
(22, 'Tech Secretariat', 'Committee Member'),
(23, 'Finance Committee', 'Committee Member'),
(24, 'Graphics Committee', 'Committee Member'),
(25, 'Copywriting Committee', 'Committee Member'),
(26, 'Socials Committee', 'Committee Member'),
(27, 'Media Committee', 'Committee Member'),
(28, 'Partnership Committee', 'Committee Member'),
(29, 'Sponsorship Committee', 'Committee Member'),
(30, 'Connect and Coordinate Committee', 'Committee Member'),
(31, 'Regional Representatives', 'Committee Member'),
(32, 'Programs Committee', 'Committee Member'),
(33, 'Logistics Committee', 'Committee Member'),
(34, 'General Member', 'General Member');

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_accredited_program_distribution_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_accredited_program_distribution_by_region` (
`Region` varchar(100)
,`Accredited_Program` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_accredited_program_highest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_accredited_program_highest_member_count` (
`Accredited_Program` varchar(99)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_accredited_program_lowest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_accredited_program_lowest_member_count` (
`Accredited_Program` varchar(99)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_avg_age_by_accredited_program`
-- (See below for the actual view)
--
CREATE TABLE `vw_avg_age_by_accredited_program` (
`Accredited_Program` varchar(99)
,`Total_Members` bigint(21)
,`Members_With_Birth_Date` bigint(21)
,`Average_Age` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_avg_age_by_year_level`
-- (See below for the actual view)
--
CREATE TABLE `vw_avg_age_by_year_level` (
`Year_Level` varchar(13)
,`Total_Members` bigint(21)
,`Members_With_Birth_Date` bigint(21)
,`Average_Age` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_avg_female_member_age`
-- (See below for the actual view)
--
CREATE TABLE `vw_avg_female_member_age` (
`Female_Members_Included` bigint(21)
,`Average_Age` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_avg_male_member_age`
-- (See below for the actual view)
--
CREATE TABLE `vw_avg_male_member_age` (
`Male_Members_Included` bigint(21)
,`Average_Age` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_avg_member_age`
-- (See below for the actual view)
--
CREATE TABLE `vw_avg_member_age` (
`Members_Included` bigint(21)
,`Average_Age` decimal(23,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_bottom_5_universities_by_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_bottom_5_universities_by_member_count` (
`University` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_gender_distribution`
-- (See below for the actual view)
--
CREATE TABLE `vw_gender_distribution` (
`Gender` varchar(13)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_gender_distribution_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_gender_distribution_by_region` (
`Region` varchar(100)
,`Gender` varchar(13)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_gender_distribution_by_scholarship_type`
-- (See below for the actual view)
--
CREATE TABLE `vw_gender_distribution_by_scholarship_type` (
`Scholarship_Type` varchar(50)
,`Gender` varchar(13)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_gender_distribution_by_year_level`
-- (See below for the actual view)
--
CREATE TABLE `vw_gender_distribution_by_year_level` (
`Year_Level` varchar(13)
,`Gender` varchar(13)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_least_common_scholarship_type`
-- (See below for the actual view)
--
CREATE TABLE `vw_least_common_scholarship_type` (
`Scholarship_Type` varchar(50)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_lowest_member_program_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_lowest_member_program_by_region` (
`Accredited_Program` varchar(99)
,`Region` varchar(100)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_male_female_ratio_by_accredited_program`
-- (See below for the actual view)
--
CREATE TABLE `vw_male_female_ratio_by_accredited_program` (
`Accredited_Program` varchar(99)
,`Male_Count` bigint(21)
,`Female_Count` bigint(21)
,`Other_Or_Unspecified_Count` bigint(21)
,`Male_to_Female_Ratio` varchar(43)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_membership_acceptance_rate`
-- (See below for the actual view)
--
CREATE TABLE `vw_membership_acceptance_rate` (
`Accepted_Record_Count` decimal(22,0)
,`Rejected_Record_Count` decimal(22,0)
,`Decided_Record_Count` decimal(22,0)
,`Acceptance_Rate_Percent` decimal(28,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_membership_rejection_rate`
-- (See below for the actual view)
--
CREATE TABLE `vw_membership_rejection_rate` (
`Accepted_Record_Count` decimal(22,0)
,`Rejected_Record_Count` decimal(22,0)
,`Decided_Record_Count` decimal(22,0)
,`Rejection_Rate_Percent` decimal(28,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_membership_status_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_membership_status_by_region` (
`Region` varchar(100)
,`Membership_Status` varchar(20)
,`Membership_Record_Count` bigint(21)
,`Unique_Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_membership_status_distribution`
-- (See below for the actual view)
--
CREATE TABLE `vw_membership_status_distribution` (
`Membership_Status` varchar(20)
,`Membership_Record_Count` bigint(21)
,`Unique_Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_membership_status_totals`
-- (See below for the actual view)
--
CREATE TABLE `vw_membership_status_totals` (
`Accepted_Record_Count` decimal(22,0)
,`Rejected_Record_Count` decimal(22,0)
,`Pending_Record_Count` decimal(22,0)
,`Unspecified_Record_Count` decimal(22,0)
,`Other_Status_Record_Count` decimal(22,0)
,`Decided_Record_Count` decimal(22,0)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_by_year_level`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_by_year_level` (
`Year_Level` varchar(13)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_per_accredited_program`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_per_accredited_program` (
`Accredited_Program` varchar(99)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_per_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_per_region` (
`Region` varchar(100)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_per_role`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_per_role` (
`Role_ID` int(11)
,`Role_Title` varchar(100)
,`Role_Level` varchar(50)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_per_scholarship_type`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_per_scholarship_type` (
`Scholarship_Type` varchar(50)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_members_per_university`
-- (See below for the actual view)
--
CREATE TABLE `vw_members_per_university` (
`University` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_member_age_group_distribution`
-- (See below for the actual view)
--
CREATE TABLE `vw_member_age_group_distribution` (
`Age_Group` varchar(12)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_member_current_age`
-- (See below for the actual view)
--
CREATE TABLE `vw_member_current_age` (
`START_ID` varchar(20)
,`Sex` varchar(10)
,`Year_Level` tinyint(3) unsigned
,`Current_Age` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_most_common_scholarship_type`
-- (See below for the actual view)
--
CREATE TABLE `vw_most_common_scholarship_type` (
`Scholarship_Type` varchar(50)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_region_highest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_region_highest_member_count` (
`Region` varchar(100)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_region_lowest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_region_lowest_member_count` (
`Region` varchar(100)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_role_category_distribution_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_role_category_distribution_by_region` (
`Region` varchar(100)
,`Role_Category` varchar(18)
,`Accepted_Assignment_Count` bigint(21)
,`Unique_Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_scholarship_distribution_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_scholarship_distribution_by_region` (
`Region` varchar(100)
,`Scholarship_Type` varchar(50)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_scholarship_type_by_award_year`
-- (See below for the actual view)
--
CREATE TABLE `vw_scholarship_type_by_award_year` (
`Award_Year` year(4)
,`Scholarship_Type` varchar(50)
,`Scholar_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_scholars_per_year_awarded`
-- (See below for the actual view)
--
CREATE TABLE `vw_scholars_per_year_awarded` (
`Award_Year` year(4)
,`Scholar_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_start_accredited_programs`
-- (See below for the actual view)
--
CREATE TABLE `vw_start_accredited_programs` (
`Accredited_Program` varchar(99)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_top_5_accredited_programs_by_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_top_5_accredited_programs_by_member_count` (
`Accredited_Program` varchar(99)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_top_5_universities_by_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_top_5_universities_by_member_count` (
`University` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_top_10_provinces_by_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_top_10_provinces_by_member_count` (
`Province` varchar(100)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_university_highest_acceptance_rate`
-- (See below for the actual view)
--
CREATE TABLE `vw_university_highest_acceptance_rate` (
`University` varchar(150)
,`Accepted_Record_Count` decimal(22,0)
,`Rejected_Record_Count` decimal(22,0)
,`Decided_Record_Count` bigint(21)
,`Acceptance_Rate_Percent` decimal(28,2)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_university_highest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_university_highest_member_count` (
`University` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_university_lowest_member_count`
-- (See below for the actual view)
--
CREATE TABLE `vw_university_lowest_member_count` (
`University` varchar(150)
,`Member_Count` bigint(21)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_university_membership_decision_rates`
-- (See below for the actual view)
--
CREATE TABLE `vw_university_membership_decision_rates` (
`University` varchar(150)
,`Accepted_Record_Count` decimal(22,0)
,`Rejected_Record_Count` decimal(22,0)
,`Decided_Record_Count` bigint(21)
,`Acceptance_Rate_Percent` decimal(30,5)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_year_level_distribution_by_region`
-- (See below for the actual view)
--
CREATE TABLE `vw_year_level_distribution_by_region` (
`Region` varchar(100)
,`Year_Level` varchar(13)
,`Member_Count` bigint(21)
);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `committee`
--
ALTER TABLE `committee`
  ADD PRIMARY KEY (`Committee_Id`),
  ADD KEY `Department_Id` (`Department_Id`);

--
-- Indexes for table `department`
--
ALTER TABLE `department`
  ADD PRIMARY KEY (`Department_ID`);

--
-- Indexes for table `members`
--
ALTER TABLE `members`
  ADD PRIMARY KEY (`START_ID`);

--
-- Indexes for table `membership_record`
--
ALTER TABLE `membership_record`
  ADD PRIMARY KEY (`Record_ID`),
  ADD KEY `fk_membership_member` (`START_ID`),
  ADD KEY `fk_membership_committee` (`Committee_ID`),
  ADD KEY `fk_membership_role` (`Role_ID`);

--
-- Indexes for table `membership_record_audit`
--
ALTER TABLE `membership_record_audit`
  ADD PRIMARY KEY (`Audit_ID`),
  ADD KEY `idx_audit_record_id` (`Record_ID`),
  ADD KEY `idx_audit_start_id` (`START_ID`),
  ADD KEY `idx_audit_action_type` (`Action_Type`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`Role_Id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `membership_record`
--
ALTER TABLE `membership_record`
  MODIFY `Record_ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=154;

--
-- AUTO_INCREMENT for table `membership_record_audit`
--
ALTER TABLE `membership_record_audit`
  MODIFY `Audit_ID` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

-- --------------------------------------------------------

--
-- Structure for view `vw_accredited_program_distribution_by_region`
--
DROP TABLE IF EXISTS `vw_accredited_program_distribution_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_accredited_program_distribution_by_region`  AS SELECT coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') AS `Region`, CASE WHEN replace(trim(`members`.`Program`),'–','-') = 'Industrial Management Engineering - Information Technology' THEN 'Industrial Management Engineering – Information Technology' ELSE trim(`members`.`Program`) END AS `Accredited_Program`, count(0) AS `Member_Count` FROM `members` WHERE `members`.`Program` is not null AND replace(trim(`members`.`Program`),'–','-') in ('Applied Mathematics','Technology and Livelihood Education With Specialization in Information and Communication Technology','Computer Engineering','Computer Science','Electronics and Communication Engineering','Industrial Management Engineering - Information Technology','Information and Communications Technology','Information Systems','Information Technology','Information Technology Systems','Management Information Systems','Statistics') GROUP BY coalesce(nullif(trim(`members`.`Region`),''),'Not Specified'), CASE WHEN replace(trim(`members`.`Program`),'–','-') = 'Industrial Management Engineering - Information Technology' THEN 'Industrial Management Engineering – Information Technology' ELSE trim(`members`.`Program`) END ;

-- --------------------------------------------------------

--
-- Structure for view `vw_accredited_program_highest_member_count`
--
DROP TABLE IF EXISTS `vw_accredited_program_highest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_accredited_program_highest_member_count`  AS SELECT `vw_members_per_accredited_program`.`Accredited_Program` AS `Accredited_Program`, `vw_members_per_accredited_program`.`Member_Count` AS `Member_Count` FROM `vw_members_per_accredited_program` WHERE `vw_members_per_accredited_program`.`Member_Count` = (select max(`vw_members_per_accredited_program`.`Member_Count`) from `vw_members_per_accredited_program`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_accredited_program_lowest_member_count`
--
DROP TABLE IF EXISTS `vw_accredited_program_lowest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_accredited_program_lowest_member_count`  AS SELECT `vw_members_per_accredited_program`.`Accredited_Program` AS `Accredited_Program`, `vw_members_per_accredited_program`.`Member_Count` AS `Member_Count` FROM `vw_members_per_accredited_program` WHERE `vw_members_per_accredited_program`.`Member_Count` = (select min(`vw_members_per_accredited_program`.`Member_Count`) from `vw_members_per_accredited_program`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_avg_age_by_accredited_program`
--
DROP TABLE IF EXISTS `vw_avg_age_by_accredited_program`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_avg_age_by_accredited_program`  AS SELECT `p`.`Accredited_Program` AS `Accredited_Program`, count(`m`.`START_ID`) AS `Total_Members`, count(`a`.`Current_Age`) AS `Members_With_Birth_Date`, round(avg(`a`.`Current_Age`),2) AS `Average_Age` FROM ((`vw_start_accredited_programs` `p` left join `members` `m` on(replace(trim(`m`.`Program`),'–','-') = replace(`p`.`Accredited_Program`,'–','-'))) left join `vw_member_current_age` `a` on(`m`.`START_ID` = `a`.`START_ID`)) GROUP BY `p`.`Accredited_Program` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_avg_age_by_year_level`
--
DROP TABLE IF EXISTS `vw_avg_age_by_year_level`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_avg_age_by_year_level`  AS SELECT CASE WHEN `vw_member_current_age`.`Year_Level` is null THEN 'Not Specified' ELSE cast(`vw_member_current_age`.`Year_Level` as char charset utf8mb4) END AS `Year_Level`, count(0) AS `Total_Members`, count(`vw_member_current_age`.`Current_Age`) AS `Members_With_Birth_Date`, round(avg(`vw_member_current_age`.`Current_Age`),2) AS `Average_Age` FROM `vw_member_current_age` GROUP BY `vw_member_current_age`.`Year_Level` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_avg_female_member_age`
--
DROP TABLE IF EXISTS `vw_avg_female_member_age`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_avg_female_member_age`  AS SELECT count(`vw_member_current_age`.`Current_Age`) AS `Female_Members_Included`, round(avg(`vw_member_current_age`.`Current_Age`),2) AS `Average_Age` FROM `vw_member_current_age` WHERE ucase(trim(`vw_member_current_age`.`Sex`)) = 'FEMALE' AND `vw_member_current_age`.`Current_Age` is not null ;

-- --------------------------------------------------------

--
-- Structure for view `vw_avg_male_member_age`
--
DROP TABLE IF EXISTS `vw_avg_male_member_age`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_avg_male_member_age`  AS SELECT count(`vw_member_current_age`.`Current_Age`) AS `Male_Members_Included`, round(avg(`vw_member_current_age`.`Current_Age`),2) AS `Average_Age` FROM `vw_member_current_age` WHERE ucase(trim(`vw_member_current_age`.`Sex`)) = 'MALE' AND `vw_member_current_age`.`Current_Age` is not null ;

-- --------------------------------------------------------

--
-- Structure for view `vw_avg_member_age`
--
DROP TABLE IF EXISTS `vw_avg_member_age`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_avg_member_age`  AS SELECT count(`vw_member_current_age`.`Current_Age`) AS `Members_Included`, round(avg(`vw_member_current_age`.`Current_Age`),2) AS `Average_Age` FROM `vw_member_current_age` WHERE `vw_member_current_age`.`Current_Age` is not null ;

-- --------------------------------------------------------

--
-- Structure for view `vw_bottom_5_universities_by_member_count`
--
DROP TABLE IF EXISTS `vw_bottom_5_universities_by_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_bottom_5_universities_by_member_count`  AS SELECT `vw_members_per_university`.`University` AS `University`, `vw_members_per_university`.`Member_Count` AS `Member_Count` FROM `vw_members_per_university` ORDER BY `vw_members_per_university`.`Member_Count` ASC, `vw_members_per_university`.`University` ASC LIMIT 0, 5 ;

-- --------------------------------------------------------

--
-- Structure for view `vw_gender_distribution`
--
DROP TABLE IF EXISTS `vw_gender_distribution`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_gender_distribution`  AS SELECT coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') AS `Gender`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_gender_distribution_by_region`
--
DROP TABLE IF EXISTS `vw_gender_distribution_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_gender_distribution_by_region`  AS SELECT coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') AS `Region`, coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') AS `Gender`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Region`),''),'Not Specified'), coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_gender_distribution_by_scholarship_type`
--
DROP TABLE IF EXISTS `vw_gender_distribution_by_scholarship_type`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_gender_distribution_by_scholarship_type`  AS SELECT coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') AS `Scholarship_Type`, coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') AS `Gender`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified'), coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_gender_distribution_by_year_level`
--
DROP TABLE IF EXISTS `vw_gender_distribution_by_year_level`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_gender_distribution_by_year_level`  AS SELECT CASE WHEN `members`.`Year_Level` is null THEN 'Not Specified' ELSE cast(`members`.`Year_Level` as char charset utf8mb4) END AS `Year_Level`, coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') AS `Gender`, count(0) AS `Member_Count` FROM `members` GROUP BY `members`.`Year_Level`, coalesce(nullif(trim(`members`.`Sex`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_least_common_scholarship_type`
--
DROP TABLE IF EXISTS `vw_least_common_scholarship_type`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_least_common_scholarship_type`  AS SELECT `vw_members_per_scholarship_type`.`Scholarship_Type` AS `Scholarship_Type`, `vw_members_per_scholarship_type`.`Member_Count` AS `Member_Count` FROM `vw_members_per_scholarship_type` WHERE `vw_members_per_scholarship_type`.`Scholarship_Type` <> 'Not Specified' AND `vw_members_per_scholarship_type`.`Member_Count` = (select min(`vw_members_per_scholarship_type`.`Member_Count`) from `vw_members_per_scholarship_type` where `vw_members_per_scholarship_type`.`Scholarship_Type` <> 'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_lowest_member_program_by_region`
--
DROP TABLE IF EXISTS `vw_lowest_member_program_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_lowest_member_program_by_region`  AS SELECT `p`.`Accredited_Program` AS `Accredited_Program`, CASE WHEN `m`.`START_ID` is null THEN 'No Members' ELSE coalesce(nullif(trim(`m`.`Region`),''),'Not Specified') END AS `Region`, count(`m`.`START_ID`) AS `Member_Count` FROM (`vw_members_per_accredited_program` `p` left join `members` `m` on(replace(trim(`m`.`Program`),'–','-') = replace(`p`.`Accredited_Program`,'–','-'))) WHERE `p`.`Member_Count` = (select min(`vw_members_per_accredited_program`.`Member_Count`) from `vw_members_per_accredited_program`) GROUP BY `p`.`Accredited_Program`, CASE WHEN `m`.`START_ID` is null THEN 'No Members' ELSE coalesce(nullif(trim(`m`.`Region`),''),'Not Specified') END ;

-- --------------------------------------------------------

--
-- Structure for view `vw_male_female_ratio_by_accredited_program`
--
DROP TABLE IF EXISTS `vw_male_female_ratio_by_accredited_program`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_male_female_ratio_by_accredited_program`  AS SELECT `gender_counts`.`Accredited_Program` AS `Accredited_Program`, `gender_counts`.`Male_Count` AS `Male_Count`, `gender_counts`.`Female_Count` AS `Female_Count`, `gender_counts`.`Other_Or_Unspecified_Count` AS `Other_Or_Unspecified_Count`, concat(`gender_counts`.`Male_Count`,':',`gender_counts`.`Female_Count`) AS `Male_to_Female_Ratio` FROM (select `p`.`Accredited_Program` AS `Accredited_Program`,count(case when ucase(trim(`m`.`Sex`)) = 'MALE' then `m`.`START_ID` end) AS `Male_Count`,count(case when ucase(trim(`m`.`Sex`)) = 'FEMALE' then `m`.`START_ID` end) AS `Female_Count`,count(case when `m`.`START_ID` is not null and (`m`.`Sex` is null or trim(`m`.`Sex`) = '' or ucase(trim(`m`.`Sex`)) not in ('MALE','FEMALE')) then `m`.`START_ID` end) AS `Other_Or_Unspecified_Count` from (`vw_start_accredited_programs` `p` left join `members` `m` on(replace(trim(`m`.`Program`),'–','-') = replace(`p`.`Accredited_Program`,'–','-'))) group by `p`.`Accredited_Program`) AS `gender_counts` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_membership_acceptance_rate`
--
DROP TABLE IF EXISTS `vw_membership_acceptance_rate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_membership_acceptance_rate`  AS SELECT `vw_membership_status_totals`.`Accepted_Record_Count` AS `Accepted_Record_Count`, `vw_membership_status_totals`.`Rejected_Record_Count` AS `Rejected_Record_Count`, `vw_membership_status_totals`.`Decided_Record_Count` AS `Decided_Record_Count`, round(`vw_membership_status_totals`.`Accepted_Record_Count` * 100.0 / nullif(`vw_membership_status_totals`.`Decided_Record_Count`,0),2) AS `Acceptance_Rate_Percent` FROM `vw_membership_status_totals` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_membership_rejection_rate`
--
DROP TABLE IF EXISTS `vw_membership_rejection_rate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_membership_rejection_rate`  AS SELECT `vw_membership_status_totals`.`Accepted_Record_Count` AS `Accepted_Record_Count`, `vw_membership_status_totals`.`Rejected_Record_Count` AS `Rejected_Record_Count`, `vw_membership_status_totals`.`Decided_Record_Count` AS `Decided_Record_Count`, round(`vw_membership_status_totals`.`Rejected_Record_Count` * 100.0 / nullif(`vw_membership_status_totals`.`Decided_Record_Count`,0),2) AS `Rejection_Rate_Percent` FROM `vw_membership_status_totals` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_membership_status_by_region`
--
DROP TABLE IF EXISTS `vw_membership_status_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_membership_status_by_region`  AS SELECT coalesce(nullif(trim(`m`.`Region`),''),'Not Specified') AS `Region`, CASE WHEN `mr`.`Status` is null OR trim(`mr`.`Status`) = '' THEN 'Not Specified' WHEN lcase(trim(`mr`.`Status`)) = 'accepted' THEN 'Accepted' WHEN lcase(trim(`mr`.`Status`)) = 'rejected' THEN 'Rejected' WHEN lcase(trim(`mr`.`Status`)) = 'pending' THEN 'Pending' ELSE trim(`mr`.`Status`) END AS `Membership_Status`, count(0) AS `Membership_Record_Count`, count(distinct `mr`.`START_ID`) AS `Unique_Member_Count` FROM (`membership_record` `mr` left join `members` `m` on(`mr`.`START_ID` = `m`.`START_ID`)) GROUP BY coalesce(nullif(trim(`m`.`Region`),''),'Not Specified'), CASE WHEN `mr`.`Status` is null OR trim(`mr`.`Status`) = '' THEN 'Not Specified' WHEN lcase(trim(`mr`.`Status`)) = 'accepted' THEN 'Accepted' WHEN lcase(trim(`mr`.`Status`)) = 'rejected' THEN 'Rejected' WHEN lcase(trim(`mr`.`Status`)) = 'pending' THEN 'Pending' ELSE trim(`mr`.`Status`) END ;

-- --------------------------------------------------------

--
-- Structure for view `vw_membership_status_distribution`
--
DROP TABLE IF EXISTS `vw_membership_status_distribution`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_membership_status_distribution`  AS SELECT CASE WHEN `membership_record`.`Status` is null OR trim(`membership_record`.`Status`) = '' THEN 'Not Specified' WHEN lcase(trim(`membership_record`.`Status`)) = 'accepted' THEN 'Accepted' WHEN lcase(trim(`membership_record`.`Status`)) = 'rejected' THEN 'Rejected' WHEN lcase(trim(`membership_record`.`Status`)) = 'pending' THEN 'Pending' ELSE trim(`membership_record`.`Status`) END AS `Membership_Status`, count(0) AS `Membership_Record_Count`, count(distinct `membership_record`.`START_ID`) AS `Unique_Member_Count` FROM `membership_record` GROUP BY CASE WHEN `membership_record`.`Status` is null OR trim(`membership_record`.`Status`) = '' THEN 'Not Specified' WHEN lcase(trim(`membership_record`.`Status`)) = 'accepted' THEN 'Accepted' WHEN lcase(trim(`membership_record`.`Status`)) = 'rejected' THEN 'Rejected' WHEN lcase(trim(`membership_record`.`Status`)) = 'pending' THEN 'Pending' ELSE trim(`membership_record`.`Status`) END ;

-- --------------------------------------------------------

--
-- Structure for view `vw_membership_status_totals`
--
DROP TABLE IF EXISTS `vw_membership_status_totals`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_membership_status_totals`  AS SELECT coalesce(sum(case when lcase(trim(`membership_record`.`Status`)) = 'accepted' then 1 else 0 end),0) AS `Accepted_Record_Count`, coalesce(sum(case when lcase(trim(`membership_record`.`Status`)) = 'rejected' then 1 else 0 end),0) AS `Rejected_Record_Count`, coalesce(sum(case when lcase(trim(`membership_record`.`Status`)) = 'pending' then 1 else 0 end),0) AS `Pending_Record_Count`, coalesce(sum(case when `membership_record`.`Status` is null or trim(`membership_record`.`Status`) = '' then 1 else 0 end),0) AS `Unspecified_Record_Count`, coalesce(sum(case when lcase(trim(`membership_record`.`Status`)) not in ('accepted','rejected','pending') and `membership_record`.`Status` is not null and trim(`membership_record`.`Status`) <> '' then 1 else 0 end),0) AS `Other_Status_Record_Count`, coalesce(sum(case when lcase(trim(`membership_record`.`Status`)) in ('accepted','rejected') then 1 else 0 end),0) AS `Decided_Record_Count` FROM `membership_record` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_by_year_level`
--
DROP TABLE IF EXISTS `vw_members_by_year_level`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_by_year_level`  AS SELECT CASE WHEN `members`.`Year_Level` is null THEN 'Not Specified' ELSE cast(`members`.`Year_Level` as char charset utf8mb4) END AS `Year_Level`, count(0) AS `Member_Count` FROM `members` GROUP BY `members`.`Year_Level` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_per_accredited_program`
--
DROP TABLE IF EXISTS `vw_members_per_accredited_program`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_per_accredited_program`  AS SELECT `p`.`Accredited_Program` AS `Accredited_Program`, count(`m`.`START_ID`) AS `Member_Count` FROM (`vw_start_accredited_programs` `p` left join `members` `m` on(replace(trim(`m`.`Program`),'–','-') = replace(`p`.`Accredited_Program`,'–','-'))) GROUP BY `p`.`Accredited_Program` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_per_region`
--
DROP TABLE IF EXISTS `vw_members_per_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_per_region`  AS SELECT coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') AS `Region`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_per_role`
--
DROP TABLE IF EXISTS `vw_members_per_role`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_per_role`  AS SELECT `r`.`Role_Id` AS `Role_ID`, `r`.`Role_Title` AS `Role_Title`, `r`.`Role_Level` AS `Role_Level`, count(distinct case when lcase(trim(`mr`.`Status`)) = 'accepted' then `mr`.`START_ID` end) AS `Member_Count` FROM (`role` `r` left join `membership_record` `mr` on(`r`.`Role_Id` = `mr`.`Role_ID`)) GROUP BY `r`.`Role_Id`, `r`.`Role_Title`, `r`.`Role_Level` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_per_scholarship_type`
--
DROP TABLE IF EXISTS `vw_members_per_scholarship_type`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_per_scholarship_type`  AS SELECT coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') AS `Scholarship_Type`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_members_per_university`
--
DROP TABLE IF EXISTS `vw_members_per_university`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_members_per_university`  AS SELECT trim(`members`.`University`) AS `University`, count(0) AS `Member_Count` FROM `members` WHERE `members`.`University` is not null AND trim(`members`.`University`) <> '' GROUP BY trim(`members`.`University`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_member_age_group_distribution`
--
DROP TABLE IF EXISTS `vw_member_age_group_distribution`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_member_age_group_distribution`  AS SELECT CASE WHEN `vw_member_current_age`.`Current_Age` is null THEN 'Unknown' WHEN `vw_member_current_age`.`Current_Age` < 18 THEN 'Under 18' WHEN `vw_member_current_age`.`Current_Age` between 18 and 20 THEN '18-20' WHEN `vw_member_current_age`.`Current_Age` between 21 and 23 THEN '21-23' WHEN `vw_member_current_age`.`Current_Age` between 24 and 26 THEN '24-26' ELSE '27 and above' END AS `Age_Group`, count(0) AS `Member_Count` FROM `vw_member_current_age` GROUP BY CASE WHEN `vw_member_current_age`.`Current_Age` is null THEN 'Unknown' WHEN `vw_member_current_age`.`Current_Age` < 18 THEN 'Under 18' WHEN `vw_member_current_age`.`Current_Age` between 18 and 20 THEN '18-20' WHEN `vw_member_current_age`.`Current_Age` between 21 and 23 THEN '21-23' WHEN `vw_member_current_age`.`Current_Age` between 24 and 26 THEN '24-26' ELSE '27 and above' END ;

-- --------------------------------------------------------

--
-- Structure for view `vw_member_current_age`
--
DROP TABLE IF EXISTS `vw_member_current_age`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_member_current_age`  AS SELECT `members`.`START_ID` AS `START_ID`, `members`.`Sex` AS `Sex`, `members`.`Year_Level` AS `Year_Level`, CASE WHEN `members`.`Date_of_Birth` is null OR `members`.`Date_of_Birth` > curdate() THEN NULL ELSE timestampdiff(YEAR,`members`.`Date_of_Birth`,curdate()) END AS `Current_Age` FROM `members` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_most_common_scholarship_type`
--
DROP TABLE IF EXISTS `vw_most_common_scholarship_type`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_most_common_scholarship_type`  AS SELECT `vw_members_per_scholarship_type`.`Scholarship_Type` AS `Scholarship_Type`, `vw_members_per_scholarship_type`.`Member_Count` AS `Member_Count` FROM `vw_members_per_scholarship_type` WHERE `vw_members_per_scholarship_type`.`Scholarship_Type` <> 'Not Specified' AND `vw_members_per_scholarship_type`.`Member_Count` = (select max(`vw_members_per_scholarship_type`.`Member_Count`) from `vw_members_per_scholarship_type` where `vw_members_per_scholarship_type`.`Scholarship_Type` <> 'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_region_highest_member_count`
--
DROP TABLE IF EXISTS `vw_region_highest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_region_highest_member_count`  AS SELECT `vw_members_per_region`.`Region` AS `Region`, `vw_members_per_region`.`Member_Count` AS `Member_Count` FROM `vw_members_per_region` WHERE `vw_members_per_region`.`Region` <> 'Not Specified' AND `vw_members_per_region`.`Member_Count` = (select max(`vw_members_per_region`.`Member_Count`) from `vw_members_per_region` where `vw_members_per_region`.`Region` <> 'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_region_lowest_member_count`
--
DROP TABLE IF EXISTS `vw_region_lowest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_region_lowest_member_count`  AS SELECT `vw_members_per_region`.`Region` AS `Region`, `vw_members_per_region`.`Member_Count` AS `Member_Count` FROM `vw_members_per_region` WHERE `vw_members_per_region`.`Region` <> 'Not Specified' AND `vw_members_per_region`.`Member_Count` = (select min(`vw_members_per_region`.`Member_Count`) from `vw_members_per_region` where `vw_members_per_region`.`Region` <> 'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_role_category_distribution_by_region`
--
DROP TABLE IF EXISTS `vw_role_category_distribution_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_role_category_distribution_by_region`  AS SELECT `role_distribution`.`Region` AS `Region`, `role_distribution`.`Role_Category` AS `Role_Category`, count(0) AS `Accepted_Assignment_Count`, count(distinct `role_distribution`.`START_ID`) AS `Unique_Member_Count` FROM (select `mr`.`START_ID` AS `START_ID`,coalesce(nullif(trim(`m`.`Region`),''),'Not Specified') AS `Region`,case when ucase(trim(`r`.`Role_Level`)) = 'GENERAL MEMBER' then 'General Member' when ucase(trim(`r`.`Role_Level`)) in ('CHIEF','DEPUTY CHIEF','COMMITTEE MEMBER') then 'Non-General Member' else 'Other/Unspecified' end AS `Role_Category` from ((`membership_record` `mr` join `members` `m` on(`mr`.`START_ID` = `m`.`START_ID`)) join `role` `r` on(`mr`.`Role_ID` = `r`.`Role_Id`)) where lcase(trim(`mr`.`Status`)) = 'accepted') AS `role_distribution` GROUP BY `role_distribution`.`Region`, `role_distribution`.`Role_Category` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_scholarship_distribution_by_region`
--
DROP TABLE IF EXISTS `vw_scholarship_distribution_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_scholarship_distribution_by_region`  AS SELECT coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') AS `Region`, coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') AS `Scholarship_Type`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Region`),''),'Not Specified'), coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_scholarship_type_by_award_year`
--
DROP TABLE IF EXISTS `vw_scholarship_type_by_award_year`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_scholarship_type_by_award_year`  AS SELECT `members`.`Year Awarded` AS `Award_Year`, coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') AS `Scholarship_Type`, count(0) AS `Scholar_Count` FROM `members` WHERE `members`.`Year Awarded` is not null AND `members`.`Year Awarded` <> 0 GROUP BY `members`.`Year Awarded`, coalesce(nullif(trim(`members`.`Scholarship Type`),''),'Not Specified') ;

-- --------------------------------------------------------

--
-- Structure for view `vw_scholars_per_year_awarded`
--
DROP TABLE IF EXISTS `vw_scholars_per_year_awarded`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_scholars_per_year_awarded`  AS SELECT `members`.`Year Awarded` AS `Award_Year`, count(0) AS `Scholar_Count` FROM `members` WHERE `members`.`Year Awarded` is not null AND `members`.`Year Awarded` <> 0 GROUP BY `members`.`Year Awarded` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_start_accredited_programs`
--
DROP TABLE IF EXISTS `vw_start_accredited_programs`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_start_accredited_programs`  AS SELECT 'Applied Mathematics' AS `Accredited_Program`union all select 'Technology and Livelihood Education With Specialization in Information and Communication Technology' AS `Name_exp_1` union all select 'Computer Engineering' AS `Computer Engineering` union all select 'Computer Science' AS `Computer Science` union all select 'Electronics and Communication Engineering' AS `Electronics and Communication Engineering` union all select 'Industrial Management Engineering – Information Technology' AS `Industrial Management Engineering – Information Technology` union all select 'Information and Communications Technology' AS `Information and Communications Technology` union all select 'Information Systems' AS `Information Systems` union all select 'Information Technology' AS `Information Technology` union all select 'Information Technology Systems' AS `Information Technology Systems` union all select 'Management Information Systems' AS `Management Information Systems` union all select 'Statistics' AS `Statistics`  ;

-- --------------------------------------------------------

--
-- Structure for view `vw_top_5_accredited_programs_by_member_count`
--
DROP TABLE IF EXISTS `vw_top_5_accredited_programs_by_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_top_5_accredited_programs_by_member_count`  AS SELECT `vw_members_per_accredited_program`.`Accredited_Program` AS `Accredited_Program`, `vw_members_per_accredited_program`.`Member_Count` AS `Member_Count` FROM `vw_members_per_accredited_program` ORDER BY `vw_members_per_accredited_program`.`Member_Count` DESC, `vw_members_per_accredited_program`.`Accredited_Program` ASC LIMIT 0, 5 ;

-- --------------------------------------------------------

--
-- Structure for view `vw_top_5_universities_by_member_count`
--
DROP TABLE IF EXISTS `vw_top_5_universities_by_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_top_5_universities_by_member_count`  AS SELECT `vw_members_per_university`.`University` AS `University`, `vw_members_per_university`.`Member_Count` AS `Member_Count` FROM `vw_members_per_university` ORDER BY `vw_members_per_university`.`Member_Count` DESC, `vw_members_per_university`.`University` ASC LIMIT 0, 5 ;

-- --------------------------------------------------------

--
-- Structure for view `vw_top_10_provinces_by_member_count`
--
DROP TABLE IF EXISTS `vw_top_10_provinces_by_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_top_10_provinces_by_member_count`  AS SELECT `province_summary`.`Province` AS `Province`, `province_summary`.`Member_Count` AS `Member_Count` FROM (select trim(`members`.`Province`) AS `Province`,count(0) AS `Member_Count` from `members` where `members`.`Province` is not null and trim(`members`.`Province`) <> '' group by trim(`members`.`Province`)) AS `province_summary` ORDER BY `province_summary`.`Member_Count` DESC, `province_summary`.`Province` ASC LIMIT 0, 10 ;

-- --------------------------------------------------------

--
-- Structure for view `vw_university_highest_acceptance_rate`
--
DROP TABLE IF EXISTS `vw_university_highest_acceptance_rate`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_university_highest_acceptance_rate`  AS SELECT `vw_university_membership_decision_rates`.`University` AS `University`, `vw_university_membership_decision_rates`.`Accepted_Record_Count` AS `Accepted_Record_Count`, `vw_university_membership_decision_rates`.`Rejected_Record_Count` AS `Rejected_Record_Count`, `vw_university_membership_decision_rates`.`Decided_Record_Count` AS `Decided_Record_Count`, round(`vw_university_membership_decision_rates`.`Acceptance_Rate_Percent`,2) AS `Acceptance_Rate_Percent` FROM `vw_university_membership_decision_rates` WHERE `vw_university_membership_decision_rates`.`Acceptance_Rate_Percent` = (select max(`vw_university_membership_decision_rates`.`Acceptance_Rate_Percent`) from `vw_university_membership_decision_rates`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_university_highest_member_count`
--
DROP TABLE IF EXISTS `vw_university_highest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_university_highest_member_count`  AS SELECT `vw_members_per_university`.`University` AS `University`, `vw_members_per_university`.`Member_Count` AS `Member_Count` FROM `vw_members_per_university` WHERE `vw_members_per_university`.`Member_Count` = (select max(`vw_members_per_university`.`Member_Count`) from `vw_members_per_university`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_university_lowest_member_count`
--
DROP TABLE IF EXISTS `vw_university_lowest_member_count`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_university_lowest_member_count`  AS SELECT `vw_members_per_university`.`University` AS `University`, `vw_members_per_university`.`Member_Count` AS `Member_Count` FROM `vw_members_per_university` WHERE `vw_members_per_university`.`Member_Count` = (select min(`vw_members_per_university`.`Member_Count`) from `vw_members_per_university`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_university_membership_decision_rates`
--
DROP TABLE IF EXISTS `vw_university_membership_decision_rates`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_university_membership_decision_rates`  AS SELECT trim(`m`.`University`) AS `University`, sum(case when lcase(trim(`mr`.`Status`)) = 'accepted' then 1 else 0 end) AS `Accepted_Record_Count`, sum(case when lcase(trim(`mr`.`Status`)) = 'rejected' then 1 else 0 end) AS `Rejected_Record_Count`, count(0) AS `Decided_Record_Count`, sum(case when lcase(trim(`mr`.`Status`)) = 'accepted' then 1 else 0 end) * 100.0 / nullif(count(0),0) AS `Acceptance_Rate_Percent` FROM (`members` `m` join `membership_record` `mr` on(`m`.`START_ID` = `mr`.`START_ID`)) WHERE `m`.`University` is not null AND trim(`m`.`University`) <> '' AND lcase(trim(`mr`.`Status`)) in ('accepted','rejected') GROUP BY trim(`m`.`University`) ;

-- --------------------------------------------------------

--
-- Structure for view `vw_year_level_distribution_by_region`
--
DROP TABLE IF EXISTS `vw_year_level_distribution_by_region`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_year_level_distribution_by_region`  AS SELECT coalesce(nullif(trim(`members`.`Region`),''),'Not Specified') AS `Region`, CASE WHEN `members`.`Year_Level` is null THEN 'Not Specified' ELSE cast(`members`.`Year_Level` as char charset utf8mb4) END AS `Year_Level`, count(0) AS `Member_Count` FROM `members` GROUP BY coalesce(nullif(trim(`members`.`Region`),''),'Not Specified'), `members`.`Year_Level` ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `committee`
--
ALTER TABLE `committee`
  ADD CONSTRAINT `committee_ibfk_1` FOREIGN KEY (`Department_Id`) REFERENCES `department` (`Department_ID`);

--
-- Constraints for table `membership_record`
--
ALTER TABLE `membership_record`
  ADD CONSTRAINT `fk_membership_committee` FOREIGN KEY (`Committee_ID`) REFERENCES `committee` (`Committee_Id`),
  ADD CONSTRAINT `fk_membership_member` FOREIGN KEY (`START_ID`) REFERENCES `members` (`START_ID`),
  ADD CONSTRAINT `fk_membership_role` FOREIGN KEY (`Role_ID`) REFERENCES `role` (`Role_Id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
