import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth.middleware';
import OpenAI from 'openai';

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
    const { messages } = req.body;

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

    res.status(200).json(reply);

  } catch (error) {
    console.error('AI Chat Error:', error);
    res.status(500).json({ error: 'Failed to generate AI response' });
  }
};
