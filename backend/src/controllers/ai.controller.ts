import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import OpenAI from 'openai';
import prisma from '../prisma/client';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export const generateSummary = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { videoTitle } = req.body;

    if (!videoTitle) {
      res.status(400).json({ error: 'videoTitle is required' });
      return;
    }

    const prompt = `
Please provide a comprehensive summary and key points for this educational video:

Title: ${videoTitle}

Please provide:
1. A detailed summary (2-3 paragraphs) of what this video likely covers based on its title
2. 3-5 key learning points that students should take away

Format your response as JSON with the following structure:
{
  "summary": "Your detailed summary here",
  "keyPoints": ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"]
}
`;

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'You are an educational assistant that provides clear, concise summaries and key learning points for educational videos.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.7,
      max_tokens: 500,
      response_format: { type: 'json_object' }
    });

    const content = completion.choices[0]?.message?.content;
    
    if (!content) {
      res.status(500).json({ error: 'OpenAI returned an empty response' });
      return;
    }

    const jsonResult = JSON.parse(content);
    res.status(200).json(jsonResult);

  } catch (error) {
    console.error('AI Summary Error:', error);
    res.status(500).json({ error: 'Failed to generate AI summary' });
  }
};

export const chat = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { messages, sessionId, sessionTitle } = req.body;
    const userId = req.user?.id;

    if (!messages || !Array.isArray(messages)) {
      res.status(400).json({ error: 'Valid messages array is required' });
      return;
    }

    const completion = await openai.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        {
          role: 'system',
          content: 'You are an expert AI Tutor helping a student learn. Provide helpful, encouraging, and clear explanations.',
        },
        ...messages
      ],
      temperature: 0.7,
      max_tokens: 1000,
    });

    const reply = completion.choices[0]?.message;
    
    if (!reply) {
      res.status(500).json({ error: 'OpenAI returned an empty response' });
      return;
    }

    if (userId && sessionId) {
      // Find or create session
      let session = await prisma.chatSession.findUnique({ where: { id: sessionId } });
      if (!session) {
        session = await prisma.chatSession.create({
          data: {
            id: sessionId,
            userId,
            title: sessionTitle || 'New Chat',
          }
        });
      }

      // We assume the last message in `messages` is the user's new message
      const lastUserMsg = messages[messages.length - 1];
      if (lastUserMsg && lastUserMsg.role === 'user') {
        await prisma.chatMessage.create({
          data: {
            sessionId: session.id,
            role: 'user',
            content: lastUserMsg.content,
          }
        });
      }

      // Save assistant reply
      await prisma.chatMessage.create({
        data: {
          sessionId: session.id,
          role: 'assistant',
          content: reply.content || '',
        }
      });
    }

    res.status(200).json(reply);

  } catch (error) {
    console.error('AI Chat Error:', error);
    res.status(500).json({ error: 'Failed to generate AI response' });
  }
};

export const getHistory = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  try {
    const { sessionId } = req.params;
    const userId = req.user?.id;

    if (!userId) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const session = await prisma.chatSession.findUnique({
      where: { id: sessionId },
      include: { messages: { orderBy: { timestamp: 'asc' } } }
    });

    if (!session || session.userId !== userId) {
      res.status(200).json({ messages: [] });
      return;
    }

    res.status(200).json({ messages: session.messages });
  } catch (error) {
    console.error('Get History Error:', error);
    res.status(500).json({ error: 'Failed to get chat history' });
  }
};
