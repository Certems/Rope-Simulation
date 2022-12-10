ArrayList<ropeSeg> ropes = new ArrayList<ropeSeg>();
float g= 9.81*0.01;

void setup(){
    size(800,800);
    ropeSeg newRope = new ropeSeg( new PVector(width/2.0, height/4.0), 16, 300.0 );
    ropes.add(newRope);
    ropes.get(0).nodes.get( ropes.get(0).nodes.size()-1 ).vel.x += 6;
}
void draw(){
    background(60,60,60);
    drawRope();
    //ropes.get(0).nodes.get( ropes.get(0).nodes.size()-1 ).pos.x = mouseX;ropes.get(0).nodes.get( ropes.get(0).nodes.size()-1 ).pos.y = mouseY;
    overlay();
}
void keyPressed(){
    if(key == '1'){
        ropeSeg newRope = new ropeSeg( new PVector(mouseX, mouseY), 8, 300.0 );
        ropes.add(newRope);
    }
    if(key == '2'){
        //ropes.get(0).nodes.get(3).pos.x = mouseX;
        //ropes.get(0).nodes.get(3).pos.y = mouseY;
    }
    if(key == '3'){
        ropes.get(0).nodes.get( ropes.get(0).nodes.size()-1 ).vel.x += 3;
    }
    if(key == '4'){
        ropes.get(0).fixedNodes.add( ropes.get(0).nodes.size()-1 );
    }
}

void drawRope(){
    for(int i=0; i<ropes.size(); i++){
        ropes.get(i).display();
        ropes.get(i).update();
    }
}
void overlay(){
    pushStyle();
    text(frameRate, 30,30);
    popStyle();
}

class node{
    PVector pos;
    PVector vel   = new PVector(0,0);
    PVector force = new PVector(0,0);

    float m;
    float k = 1.2;
    float dConst = 0.015;

    node(PVector initialPos, float mass){
        pos = initialPos;
        m   = mass;
    }

    void display(){
        pushStyle();
        fill(255);
        ellipse(pos.x, pos.y, 10, 10);
        popStyle();
    }
    void calcForce(node n1, node n2, float nLen){
        /*
        n1 and n2 are the nodes above and below of this node (in the array)
        nLen is the natural length
        Nodes feel;
        .(0)Gravity
        .(1)Elastic force between adjacent
        .(3)Drag forces
        */
        force.x = 0;
        force.y = 0;
        //(0)Gravity
        force.x += 0;
        force.y += m*g;

        //(1)F = kx
        PVector r;
        float rM;
        float x;

        if(n1 != null){
            r  = new PVector(n1.pos.x -pos.x, n1.pos.y -pos.y);
            rM = sqrt( pow(r.x,2) + pow(r.y,2) );
            x  = rM - nLen; //+ve means actual in r direction e.g contracting / longer than natural length
            force.x += r.x *(1.0/rM)*(k*x);
            force.y += r.y *(1.0/rM)*(k*x);
        }
        if(n2 != null){
            r  = new PVector(n2.pos.x -pos.x, n2.pos.y -pos.y);
            rM = sqrt( pow(r.x,2) + pow(r.y,2) );
            x  = rM - nLen; //+ve means actual in r direction e.g contracting / longer than natural length
            force.x += r.x *(1.0/rM)*(k*x);
            force.y += r.y *(1.0/rM)*(k*x);
        }
        
        //(3)Drag
        force.x -= dConst*vel.x;
        force.y -= dConst*vel.y;
    }
    void calcVel(){
        vel.x += force.x / m;
        vel.y += force.y / m;
    }
    void calcPos(){
        pos.x += vel.x;
        pos.y += vel.y;
    }
    void calcCollision(){
        //Check appropriate terrain here
        if( (pos.x+vel.x <0) || (pos.x+vel.x >width) ){    //If colliding with screen border
            vel = reboundVel(vel, new PVector(0,1));
        }
        if( (pos.y+vel.y <0) || (pos.y+vel.y >height) ){
            vel = reboundVel(vel, new PVector(1,0));
        }
    }
    PVector reboundVel(PVector v1, PVector tWall){
        /*
        v1 = approach velocity
        tWall = wall tangent vector
        v2 = exit velocity
        */
        float e = 0.8;
        PVector nWall = new PVector(tWall.y, -tWall.x);
        if( v1.x*nWall.x + v1.y*nWall.y > 0 ){         //Corrects normal direction
            nWall.x *= -1;nWall.y *= -1;}
        if( v1.x*tWall.x + v1.y*tWall.y <= 0 ){       //Corrects tangent direction
            tWall.x *= -1;tWall.y *= -1;}
        PVector cPerp = new PVector( ((v1.x*nWall.x) + (v1.y*nWall.y))*e*nWall.x , ((v1.x*nWall.x) + (v1.y*nWall.y))*e*nWall.y );
        PVector cPara = new PVector( ((v1.x*tWall.x) + (v1.y*tWall.y))  *tWall.x , ((v1.x*tWall.x) + (v1.y*tWall.y))  *tWall.y );
        PVector v2    = new PVector( cPara.x - cPerp.x, cPara.y - cPerp.y );
        return v2;
    }
}

class ropeSeg{
    ArrayList<node> nodes = new ArrayList<node>();
    ArrayList<Integer> fixedNodes = new ArrayList<Integer>();

    PVector oPos;   //Origin pos

    float tL;   //Total length
    float l;    //Natural length

    int n;

    ropeSeg(PVector originPos, int nodeNumber, float totalLength){
        oPos = originPos;
        n  = nodeNumber;
        tL = totalLength;
        l  = tL/n;
        createNodeString();
        fixedNodes.add(0);
    }

    void display(){
        displayCurve();
        //displayNodes();
    }
    void update(){
        updateNodeVals();
    }
    void displayCurve(){
        pushStyle();
        noFill();
        //stroke(180,255,180);
        stroke( 255*(nodes.get(nodes.size()-1).pos.x / width), 200, 255*(nodes.get(nodes.size()-1).pos.y / height) );
        strokeWeight(3);
        beginShape();
        curveVertex(nodes.get(0).pos.x, nodes.get(0).pos.y);
        for(int i=0; i<nodes.size(); i++){
            curveVertex(nodes.get(i).pos.x, nodes.get(i).pos.y);
        }
        curveVertex(nodes.get(nodes.size()-1).pos.x, nodes.get(nodes.size()-1).pos.y);
        endShape();
        popStyle();
    }
    void displayNodes(){
        for(int i=0; i<nodes.size(); i++){
            nodes.get(i).display();
        }
    }
    void updateNodeVals(){
        for(int i=0; i<nodes.size(); i++){
            if(i == 0){
                nodes.get(i).calcForce( null, nodes.get((i+1)%(nodes.size())), l );
            }
            else if(i == nodes.size() -1){
                nodes.get(i).calcForce( nodes.get((i-1)%(nodes.size())), null, l );
            }
            else{
                nodes.get(i).calcForce( nodes.get((i-1)%(nodes.size())), nodes.get((i+1)%(nodes.size())), l );
            }
            nodes.get(i).calcVel();
            nodes.get(i).calcCollision();
        }
        for(int i=0; i<fixedNodes.size(); i++){
            nodes.get( int(fixedNodes.get(i)) ).vel.x = 0;
            nodes.get( int(fixedNodes.get(i)) ).vel.y = 0;
        }
        for(int i=0; i<nodes.size(); i++){
            nodes.get(i).calcPos();
        }
    }
    void createNodeString(){
        for(int i=0; i<n; i++){
            node newNode = new node( new PVector(oPos.x, oPos.y +(i*tL/n)), 2.0);
            nodes.add(newNode);
        }
    }
}
