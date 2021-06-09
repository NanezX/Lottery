import React, { useContext } from "react";
import { Container, Jumbotron, Image } from "react-bootstrap";

import { Web3Context } from "../web3";

export default function Home() {
  const { account } = useContext(Web3Context);

  return (
    <div className="app-container h-100">
      <Jumbotron className="home-page mt-5">
        <Container className="text-center">
          <h1>Welcome to no loss lottery</h1>
            <p> Current pot:  </p> 
            <p> Last Winner:  </p> 
            <p> Next Lottery raffle in:  </p> 
          {!account && (
              <h4 className="mt-5 text-secondary">
                Let's start by connecting to a web3 provider!
              </h4>
          )}
        </Container>
      </Jumbotron>

    </div>
  );
}
