import React from 'react'
import { Container, Row, Col, Card, Button } from 'react-bootstrap'
function Home() {
  return (
    <Container>
      <Row className="text-center mb-4">
        <Col>
          <h1 className="display-4">Welcome to TaskForge Pro</h1>
          <p className="lead">Modern SaaS Task Management Platform</p>
        </Col>
      </Row>
      <Row>
        <Col md={4}>
          <Card className="mb-3">
            <Card.Body>
              <Card.Title>Manage Tasks</Card.Title>
              <Card.Text>Create, track, and organize tasks efficiently</Card.Text>
              <Button variant="primary" href="/tasks">View Tasks</Button>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="mb-3">
            <Card.Body>
              <Card.Title>Team Collaboration</Card.Title>
              <Card.Text>Work together with your team members</Card.Text>
              <Button variant="primary" href="/team">View Team</Button>
            </Card.Body>
          </Card>
        </Col>
        <Col md={4}>
          <Card className="mb-3">
            <Card.Body>
              <Card.Title>Analytics</Card.Title>
              <Card.Text>Track progress and productivity metrics</Card.Text>
              <Button variant="primary" href="/settings">View Analytics</Button>
            </Card.Body>
          </Card>
        </Col>
      </Row>
    </Container>
  )
}
export default Home
