CREATE TABLE IF NOT EXISTS camping (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(20) NOT NULL, -- 'tent' or 'campfire'
    model VARCHAR(50) NOT NULL,
    x FLOAT NOT NULL,
    y FLOAT NOT NULL,
    z FLOAT NOT NULL,
    stashID VARCHAR(50), -- For tents only
    heading FLOAT NOT NULL
);