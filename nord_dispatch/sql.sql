-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Mar 23, 2026 at 11:47 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `qbcore_ad8a26`
--

-- --------------------------------------------------------

--
-- Table structure for table `noctavia_mdt_dispatch`
--

CREATE TABLE `noctavia_mdt_dispatch` (
  `id` int(11) NOT NULL,
  `dispatch_id` int(11) NOT NULL,
  `code` varchar(20) NOT NULL,
  `title` varchar(200) NOT NULL,
  `street` varchar(200) DEFAULT NULL,
  `priority` int(11) NOT NULL DEFAULT 3,
  `coords` longtext DEFAULT NULL,
  `info` longtext DEFAULT NULL,
  `ts_created` timestamp NOT NULL DEFAULT current_timestamp(),
  `units` text DEFAULT NULL,
  `status` enum('open','assigned','closed') NOT NULL DEFAULT 'open',
  `assigned_by` varchar(64) DEFAULT NULL,
  `closed_by` varchar(64) DEFAULT NULL,
  `ts_assigned` datetime DEFAULT NULL,
  `ts_closed` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `noctavia_mdt_dispatch`
--

-- --------------------------------------------------------

--
-- Table structure for table `noctavia_mdt_dispatch_logs`
--

CREATE TABLE `noctavia_mdt_dispatch_logs` (
  `id` int(11) NOT NULL,
  `dispatch_id` int(11) NOT NULL,
  `action` varchar(100) NOT NULL,
  `payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`payload`)),
  `ts` datetime NOT NULL,
  `author` varchar(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_general_ci;

--
-- Dumping data for table `noctavia_mdt_dispatch_logs`
--

-- --------------------------------------------------------

--
-- Table structure for table `noctavia_mdt_dispatch_units`
--

CREATE TABLE `noctavia_mdt_dispatch_units` (
  `id` int(11) NOT NULL,
  `dispatch_id` int(11) NOT NULL,
  `citizenid` varchar(64) NOT NULL,
  `callsign` varchar(32) DEFAULT NULL,
  `ts_assigned` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `noctavia_mdt_dispatch_units`
--

-- Indexes for dumped tables
--

--
-- Indexes for table `noctavia_mdt_dispatch`
--
ALTER TABLE `noctavia_mdt_dispatch`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_dispatch_status` (`status`),
  ADD KEY `idx_dispatch_created` (`ts_created`);

--
-- Indexes for table `noctavia_mdt_dispatch_logs`
--
ALTER TABLE `noctavia_mdt_dispatch_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_logs_dispatch` (`dispatch_id`),
  ADD KEY `idx_logs_author` (`author`),
  ADD KEY `idx_logs_ts` (`ts`);

--
-- Indexes for table `noctavia_mdt_dispatch_units`
--
ALTER TABLE `noctavia_mdt_dispatch_units`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uniq_dispatch_unit` (`dispatch_id`,`citizenid`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `noctavia_mdt_dispatch`
--
ALTER TABLE `noctavia_mdt_dispatch`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9608;

--
-- AUTO_INCREMENT for table `noctavia_mdt_dispatch_logs`
--
ALTER TABLE `noctavia_mdt_dispatch_logs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT for table `noctavia_mdt_dispatch_units`
--
ALTER TABLE `noctavia_mdt_dispatch_units`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
