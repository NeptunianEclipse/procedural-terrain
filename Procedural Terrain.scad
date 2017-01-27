/* PARAMETERS
***************************************************/

// Map size
cellsX = 64;
cellsY = 64;

// Physical mesh
cellSize = 10;
terrainBottomDepth = 5;
oceanInset = 0.01;
heightMultiplier = 1;

// Heightmap generation
minHeight = 1;
heightRange = 22;
smoothness = 0.75;

// Colouring and macro features
undergroundColor = [0.4, 0.3, 0.2];
oceanHeight = 8;
oceanColour = [0, 0, 1, 0.6];
beachHeight = 0.3;
sandColour = [1, 0.9, 0.4];
minHeightColour = [0, 0.8, 0];
maxHeightColour = [0.4, 0.4, 0];
mountainGradientBeginHeight = 15;
mountainGradientEndHeight = 17;
mountainBeginGradient = 1.3;
mountainColour = [0.4, 0.4, 0.4];
snowMinHeight = 20;
snowColour = [1, 1, 1];
cliffMinGradient = 1.5;
cliffColour = [0.5, 0.6, 0.3];

// Objects
treeDensity = 0.3; // Trees per tile
numTreeAttempts = treeDensity * cellsX * cellsY;
treeTrunkColour = [0.7, 0.5, 0];
treeLeavesColour = [0, 0.4, 0];
maxTreeAngle = 5;
grassDensity = 0.3; // Grasses per tile
numGrassAttempts = grassDensity * cellsX * cellsY;
grassColour = [0.4, 0.8, 0];
maxGrassAngle = 5;

/* TERRAIN OBJECTS
***************************************************/

// Creates a random terrain object
module RandomTerrain() {
    // Heightmap
    heights = generateDiamondSquareHeights(cellsX + 1, cellsY + 1, minHeight, heightRange);
    
    // Points
    bottomLayerPoints = getBottomLayerPoints(cellsX, cellsY, cellSize);
    topLayerPoints = getTopLayerPoints(cellsX, cellsY, cellSize, heights);
    points = concat(bottomLayerPoints, topLayerPoints);

    // Faces
    bottomLayerFaces = getBottomLayerFaces(cellsX, cellsY);
    posXSideFaces = getPosXSideFaces(cellsX, cellsY);
    posYSideFaces = getPosYSideFaces(cellsX, cellsY);
    negXSideFaces = getNegXSideFaces(cellsX, cellsY);
    negYSideFaces = getNegYSideFaces(cellsX, cellsY);
    faces = concat(bottomLayerFaces, posXSideFaces, posYSideFaces, negXSideFaces, negYSideFaces);
    
    // Surface polyhedrons
    for(x = [0 : cellsX - 1]) {
        for(y = [0 : cellsY - 1]) {
            triColours = [for(i = [0 : 1]) [random(0, 1), random(0, 1), random(0, 1)]];
            translate([x * cellSize, y * cellSize, 0]) {
                if((x + y) % 2 == 1) {
                    TerrainTriangle(x, y, heights, "negX", "posY", triColours[0]);
                    TerrainTriangle(x, y, heights, "posX", "negY", triColours[1]);
                } else {
                    TerrainTriangle(x, y, heights, "negX", "negY", triColours[0]);
                    TerrainTriangle(x, y, heights, "posX", "posY", triColours[1]);
                }
            }
        }
    }
    
    // Ocean
    color(oceanColour) {
        translate([oceanInset / 2, oceanInset / 2, oceanInset / 2 - terrainBottomDepth]) {
            cube([cellsX * cellSize - oceanInset, cellsY * cellSize - oceanInset, oceanHeight * cellSize - oceanInset + terrainBottomDepth]);
        }
    }
    
    // Trees
    for(i = [0 : numTreeAttempts]) {
        randX = random(0, cellsX);
        randY = random(0, cellsY);
        height = averageVector([
            heights[floor(randX)][floor(randY)],
            heights[floor(randX) + 1][floor(randY)],
            heights[floor(randX)][floor(randY) + 1],
            heights[floor(randX) + 1][floor(randY) + 1],
        ]);
        rotation = [random(-maxTreeAngle, maxTreeAngle), random(-maxTreeAngle, maxTreeAngle), random(0, 360)];
        if(height > oceanHeight + beachHeight && height < mountainGradientEndHeight) {
            translate([randX * cellSize, randY * cellSize, height * cellSize * heightMultiplier]) {
                rotate(rotation) {
                    scale([cellSize, cellSize, cellSize]) {
                        Tree();
                    }
                }
            }
        }
        
            
    }
    
    // Grasses
    for(i = [0 : numGrassAttempts]) {
        randX = random(0, cellsX);
        randY = random(0, cellsY);
        height = averageVector([
            heights[floor(randX)][floor(randY)],
            heights[floor(randX) + 1][floor(randY)],
            heights[floor(randX)][floor(randY) + 1],
            heights[floor(randX) + 1][floor(randY) + 1],
        ]);
        rotation = [random(-maxGrassAngle, maxGrassAngle), random(-maxGrassAngle, maxGrassAngle), random(0, 360)];
        if(height > oceanHeight + beachHeight && height < mountainGradientEndHeight) {
            translate([randX * cellSize, randY * cellSize, height * cellSize * heightMultiplier]) {
                rotate(rotation) {
                    scale([cellSize, cellSize, cellSize]) {
                        TallGrass();
                    }
                }
            }
        } 
    }
        
    // Base polyhedron
    color(undergroundColor) {
        polyhedron(points = points, faces = faces);
    }
}

module TerrainTriangle(cellX, cellY, heightsArray, triXDirection, triYDirection, triColour) {
    points = triXDirection == "negX" ?
        (triYDirection == "negY" ? 
            [[0, 0, cellSize * heightMultiplier * heightsArray[cellX][cellY]],
            [0, cellSize, cellSize * heightMultiplier * heightsArray[cellX][cellY + 1]],
            [cellSize, 0, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY]]] :         
            [[0, 0, cellSize * heightMultiplier * heightsArray[cellX][cellY]],
            [0, cellSize, cellSize * heightMultiplier * heightsArray[cellX][cellY + 1]],
            [cellSize, cellSize, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY + 1]]]
        ) : (triYDirection == "negY" ?
            [[0, 0, cellSize * heightMultiplier * heightsArray[cellX][cellY]],
            [cellSize, cellSize, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY + 1]],
            [cellSize, 0, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY]]] :
            [[0, cellSize, cellSize * heightMultiplier * heightsArray[cellX][cellY + 1]],
            [cellSize, cellSize, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY + 1]],
            [cellSize, 0, cellSize * heightMultiplier * heightsArray[cellX + 1][cellY]]]
        );
    
    color(clampVector(colourForTerrainTriangle(points), 0, 1)) {
        polyhedron(points = points, faces = [[0, 1, 2]]);
    }
}

// Pine tree object
module Tree() {
    translate([0, 0, 0]) {
        color(treeTrunkColour) {
            hull() {
                cube([0.1, 0.1, 2], center=true);
                rotate([0, 0, 45]) cube([0.1, 0.1, 2], center=true);
            }
        }
    }
    translate([0, 0, 1]) {
        color(treeLeavesColour) {
            //cube([0.3, 0.3, 0.5], center=true);
            leavesSegments = 5;
            baseLeavesWidth = 0.5;
            leavesWidthDropoff = 0.1;
            leavesSegmentHeight = 0.2;
            for(i = [0 : leavesSegments - 1]) {
                translate([0, 0, -0.5 + i * leavesSegmentHeight]) {
                    cube([baseLeavesWidth - i * leavesWidthDropoff, baseLeavesWidth - i * leavesWidthDropoff, leavesSegmentHeight], center=true);
                    
                }
                
            }
        }
    }
}

module TallGrass() {
    grassSpokes = 1;
    grassSpacing = 0.1;
    grassWidth = 0.03;
    grassHeight = 0.3;
    grassAngleIncrease = 15;
    for(x = [-grassSpokes : grassSpokes]) {
        for(y = [-grassSpokes : grassSpokes]) {
            translate([x * grassSpacing, y * grassSpacing, grassHeight / 2]) {
                rotate([-y * grassAngleIncrease, x * grassAngleIncrease, 0]) {
                    color(grassColour) {
                        cube([grassWidth, grassWidth, grassHeight], true);
                    }
                }
            }
        }
    }
}


/* TERRAIN COLOUR FUNCTIONS
***************************************************/

function colourForTerrainTriangle(points) = let(
    averageHeight = (points[0][2] / (cellSize * heightMultiplier) + points[1][2] / (cellSize * heightMultiplier) + points[2][2] / (cellSize * heightMultiplier)) / 3,
    gradient = gradientForTerrainTriangle(points),
    heightColour = colourForHeight(averageHeight)
    )
    averageHeight > mountainGradientBeginHeight && gradient > mountainBeginGradient ?
    mountainColour : (
        averageHeight > oceanHeight + beachHeight && gradient > cliffMinGradient ?
        cliffColour :
        heightColour
    );

function colourForHeight(height) = 
    height >= snowMinHeight ?
    snowColour : (
        height >= mountainGradientEndHeight ?
        mountainColour : (
            height < oceanHeight + beachHeight ?
            sandColour :
            lerpVector(minHeightColour, maxHeightColour, (height - minHeight) / heightRange)
        )
    );
    

/* TERRAIN MESH GENERATION FUNCTIONS
***************************************************/

function getPoints(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    totalLayerPoints = pointsX * pointsY,
    totalPoints = totalLayerPoints * 2
    ) totalPoints;

// Returns an array of the points on the bottom half of the final polyhedron
function getBottomLayerPoints(cellsX, cellsY, cellSize) = 
    [for(x = [0 : cellsX], y = [0 : cellsY])
        [x * cellSize, y * cellSize, -terrainBottomDepth]
    ];

function getBottomLayerFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1
    )
    [for(x = [0 : cellsX - 1], y = [0 : cellsY - 1], triNum = [0 : 1])
        triNum == 0 ? 
        [x * pointsY + y, (x + 1) * pointsY + y, (x + 1) * pointsY + y + 1] : 
        [x * pointsY + y, (x + 1) * pointsY + y + 1, x * pointsY + y + 1]
    ];

// Returns an array of the points on the top half of the final polyhedron
function getTopLayerPoints(cellsX, cellsY, cellSize, heights) =
    [for(x = [0 : cellsX], y = [0 : cellsY])
        [x * cellSize, y * cellSize, heights[x][y] * cellSize * heightMultiplier]
    ];

// Returns an array of the faces connecting the points on the top half of the final polyhedron
// Each "cell" is represented by two triangles - the direction of these triangles alternates
function getTopLayerFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    off = pointsX * pointsY
    )
    [for(x = [0 : cellsX - 1], y = [0 : cellsY - 1], triNum = [0 : 1])
        (x + y) % 2 == 1 ? (
            triNum == 0 ?
            [x * pointsY + y + 1 + off, (x + 1) * pointsY + y + off, x * pointsY + y + off] :
            [x * pointsY + y + 1 + off, (x + 1) * pointsY + y + 1 + off, (x + 1) * pointsY + y + off]
        ) : (
            triNum == 0 ? 
            [(x + 1) * pointsY + y + 1 + off, (x + 1) * pointsY + y + off, x * pointsY + y + off] : 
            [x * pointsY + y + 1 + off, (x + 1) * pointsY + y + 1 + off, x * pointsY + y + off]
        )
    ];

function getPosXSideFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    off = pointsX * pointsY,
    x = cellsX
    )
    [for(y = [0 : cellsY - 1], triNum = [0 : 1])
        triNum == 0 ? 
        [x * pointsY + y, x * pointsY + y + off, x * pointsY + y + 1 + off] : 
        [x * pointsY + y, x * pointsY + y + 1 + off, x * pointsY + y + 1]
    ];

function getPosYSideFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    off = pointsX * pointsY,
    y = cellsY
    )
    [for(x = [0 : cellsX - 1], triNum = [0 : 1])
        triNum == 0 ? 
        [(x + 1) * pointsY + y, (x + 1) * pointsY + y + off, x * pointsY + y + off] : 
        [(x + 1) * pointsY + y, x * pointsY + y + off, x * pointsY + y]
    ];

function getNegXSideFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    off = pointsX * pointsY,
    x = 0
    )
    [for(y = [0 : cellsY - 1], triNum = [0 : 1])
        triNum == 0 ? 
        [x * pointsY + y + 1, x * pointsY + y + 1 + off, x * pointsY + y + off] : 
        [x * pointsY + y + 1, x * pointsY + y + off, x * pointsY + y]
    ];

function getNegYSideFaces(cellsX, cellsY) = let(
    pointsX = cellsX + 1,
    pointsY = cellsY + 1,
    off = pointsX * pointsY,
    y = 0
    )
    [for(x = [0 : cellsX - 1], triNum = [0 : 1])
        triNum == 0 ? 
        [x * pointsY + y, x * pointsY + y + off, (x + 1) * pointsY + y + off] : 
        [x * pointsY + y, (x + 1) * pointsY + y + off, (x + 1) * pointsY + y]
    ];


/* HEIGHTMAP GENERATION FUNCTIONS
***************************************************/

// Returns a 2D array of randomly generated heights for a number of points
function getBasicRandomHeights(pointsX, pointsY, minHeight, heightRange) = 
    [for(x = [0 : pointsX - 1]) 
        [for(y = [0 : pointsY - 1]) 
            random(minHeight, minHeight + heightRange)
        ]
    ];

function generateDiamondSquareHeights(pointsX, pointsY, minHeight, heightRange) =
    DS(getBaseDSArray(pointsX, pointsY, minHeight, heightRange), pointsX, pointsY, minHeight, heightRange, 1);

function getBaseDSArray(pointsX, pointsY, minHeight, heightRange) = 
    [for(x = [0 : pointsX - 1])
        [for(y = [0 : pointsY - 1])
            (x == 0 && y == 0) || (x == pointsX - 1 && y == 0) || (x == 0 && y == pointsY - 1) || (x == pointsX - 1 && y == pointsY - 1) ? 
            random(minHeight, minHeight + heightRange) : 0
        ]
    ];

function DS(heights, pointsX, pointsY, minHeight, heightRange, iteration) =
    iteration <= numIterations(pointsX) ?
    DS(DSIteration(heights, pointsX, pointsY, minHeight, heightRange, iteration), pointsX, pointsY, minHeight, heightRange, iteration + 1) :
    heights;

// Performs one diamond square step based on the iteration number
function DSIteration(heights, pointsX, pointsY, minHeight, heightRange, iteration) =
    DSSquare(DSDiamond(heights, pointsX, pointsY, minHeight, heightRange, iteration), pointsX, pointsY, minHeight, heightRange, iteration);

function DSDiamond(heights, pointsX, pointsY, minHeight, heightRange, iteration) =
    [for(x = [0 : pointsX - 1])
        [for(y = [0 : pointsY - 1]) let(
            distance = floor(pointsX / (pow(2, iteration - 1))),
            halfDistance = ceil((distance - 1) / 2),
            baseX = (pointsX - 1) * pow(0.5, iteration),
            baseY = (pointsY - 1) * pow(0.5, iteration)
            )
            (x - baseX) % distance == 0 && (y - baseY) % distance == 0 ?
            averageVector([
                heights[x - halfDistance][y - halfDistance],
                heights[x - halfDistance][y + halfDistance],
                heights[x + halfDistance][y - halfDistance],
                heights[x + halfDistance][y + halfDistance]
            ]) + getDSHeightOffset(iteration, minHeight, heightRange) :
            heights[x][y]
        ]
    ];

function DSSquare(heights, pointsX, pointsY, minHeight, heightRange, iteration) =
    [for(x = [0 : pointsX - 1])
        [for(y = [0 : pointsY - 1]) let(
            distance = floor(pointsX / (pow(2, iteration - 1))),
            halfDistance = ceil((distance - 1) / 2)
            )
            x % halfDistance == 0 && y % halfDistance == 0 &&
            (((x / halfDistance) % 2 == 0 && (y / halfDistance) % 2 == 1) ||
            ((x / halfDistance) % 2 == 1 && (y / halfDistance) % 2 == 0)) ? 
            averageVector([
                x - halfDistance >= 0 ? heights[x - halfDistance][y] : 0,
                x + halfDistance <= pointsX - 1 ? heights[x + halfDistance][y] : 0,
                y - halfDistance >= 0 ? heights[x][y - halfDistance] : 0,
                y + halfDistance <= pointsY - 1 ? heights[x][y + halfDistance] : 0
            ], (x - halfDistance >= 0 ? 1 : 0) + 
               (x + halfDistance <= pointsX - 1 ? 1 : 0) + 
               (y - halfDistance >= 0 ? 1 : 0) +
               (y + halfDistance <= pointsY - 1 ? 1 : 0)) + 
            getDSHeightOffset(iteration, minHeight, heightRange) :
            heights[x][y]
        ]
    ];

function getDSHeightOffset(iteration, minHeight, heightRange) = 
    random(-heightRange / 2, heightRange / 2) / (pow(2, smoothness * iteration));

function numIterations(size) = floor(customLog(size - 1, 2));


/* MISC FUNCTIONS
***************************************************/

// Returns a random number between low and high
function random(low, high) = rands(low, high, 1)[0];
  
// Returns the linear interpolation between low and high at fraction  
function lerp(low, high, fraction) = (high - low) * fraction + low;
    
// Returns the linear interpolation of each vector element between its low and high at fraction
function lerpVector(lowVector, highVector, fraction) = 
    [for(i = [0 : len(lowVector) - 1]) lerp(lowVector[i], highVector[i], fraction)];
        
function clamp(value, low, high) = min(max(value, low), high);
    
function clampVector(vector, low, high) = [for(i = [0 : len(vector) - 1]) clamp(vector[i], low, high)];

// Returns the sum of all elements in a vector
function sumVector(vector) = sumv(vector, len(vector) - 1, 0);
    
function sumv(vector, end, start = 0) = 
    (end == start ? vector[end] : vector[end] + sumv(vector, end - 1, start));

// Returns the average of all elements in a vector
function averageVector(vector, divideNum = 0) = 
    sumVector(vector) / (divideNum > 0 ? divideNum : len(vector));

function averageColours(colour1, colour2) =
    [averageVector([colour1[0], colour2[0]]), averageVector([colour1[1], colour2[1]]), averageVector([colour1[2], colour2[2]])];

function gradientForTerrainTriangle(points) = let (
    high = max(points[0][2], max(points[1][2], points[2][2])) / cellSize,
    low = min(points[0][2], min(points[1][2], points[2][2])) / cellSize
    )
    high - low;

// Returns the log of operand base base
function customLog(operand, base) = log(operand) / log(base);

// Echos the given vector over multiple lines
module echoVector(vector) {
    echo();
    for(i = [0 : len(vector) - 1]) {
        echo(vector[i]);
    }
    echo();
}


/* INIT
***************************************************/

RandomTerrain();