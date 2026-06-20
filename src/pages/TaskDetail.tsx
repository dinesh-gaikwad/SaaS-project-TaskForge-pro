import React from 'react'
import { Container, Card, Button } from 'react-bootstrap'
import { useParams } from 'react-router-dom'
function TaskDetail() {
  const { id } = useParams()
  return (
    <Container>
      <h1 className="mb-4">Task #{id}</h1>
      <Card>
        <Card.Body>
          <Card.Title>Task Details</Card.Title>
          <Card.Text>Complete task information</Card.Text>
          <Button variant="primary">Edit Task</Button>
        </Card.Body>
      </Card>
    </Container>
  )
}
export default TaskDetail
